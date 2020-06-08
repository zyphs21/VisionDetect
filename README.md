# VisionDetect : 利用 Vision 给无人机图传加上人脸识别功能


Vision 是 iOS 上一个机器视觉的框架，它可以对图片和视频进行多种机器视觉相关的任务处理。Vision 里的人脸识别功能是最常用的功能之一，经过几次的迭代，它的识别效果已经很不错了，具体可以看看 `WWDC2017 Session 506`, `WWDC2018 Session 716、717` 和 `WWDC 2019 Session 222`，本文的 [Demo-VisoinDetect](https://github.com/zyphs21/VisionDetect) 有些代码就是从这些 Session 中的示例代码修改而来。

这里我们要做的东西是: 将 DJISDK 提供给我们的视频流数据，传入 Vision 框架进行人脸识别，然后拿到人脸信息在图传界面显示出来。效果如下：

![](https://cdn.jsdelivr.net/gh/zyphs21/VisionDetect/detectFace.gif)

<img src="https://cdn.jsdelivr.net/gh/zyphs21/VisionDetect/face.jpg" width = "544" height = "320" alt="" align=center />

## 一、获取无人机图传视频流

> 相信大家对无人机App激活连接这部分已经比较熟悉了，这里就不赘述，不熟悉的话请查阅 DJISDK 文档

### 1. 注册 VideoFrameProcessor，获取到 VideoFrameYUV

视频流数据其实就是一帧帧的图片，而 Vision 可以接收 `CVPixelBuffer` 的图片数据，所以我们需要把图传数据转换成 `CVPixelBuffer` 。

这里我们利用 DJIWidget 的 `VideoFrameProcessor` 来获取视频流的帧数据。

```Swift
import DJISDK
import DJIWidget

@IBOutlet weak var videoPreview: UIView!

override func viewDidLoad() {
    super.viewDidLoad()

    DJIVideoPreviewer.instance().setView(videoPreview)
    DJIVideoPreviewer.instance().enableHardwareDecode = true
    DJIVideoPreviewer.instance().enableFastUpload = true
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    DJIVideoPreviewer.instance().type = .autoAdapt
    // 调用 registFrameProcessor 方法
    DJIVideoPreviewer.instance()?.registFrameProcessor(self)
    DJIVideoPreviewer.instance()?.start()
    DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    DJIVideoPreviewer.instance().unSetView()
    DJIVideoPreviewer.instance().close()
}
```

上面是我们常规获取视频流的方法，不过我们还调用了 `registFrameProcessor` 的方法，调用了该方法后，我们需要实现 `VideoFrameProcessor` 的代理方法，从代理方法中可以获取到视频流的 `VideoFrameYUV` 数据。

### 2. 将 VideoFrameYUV 转换成 CVPixelBuffer

```Swift
// MARK: - VideoFrameProcessor
extension DJIVideoViewController: VideoFrameProcessor {
    
    func videoProcessorEnabled() -> Bool {
        return true
    }
    
    func videoProcessFrame(_ frame: UnsafeMutablePointer<VideoFrameYUV>!) {
        let resolution = CGSize(width: CGFloat(frame.pointee.width), height: CGFloat(frame.pointee.height))
        
        if frame.pointee.cv_pixelbuffer_fastupload != nil {
            // 把 cv_pixelbuffer_fastupload 转换成 CVPixelBuffer 对象
            let cvBuf = unsafeBitCast(frame.pointee.cv_pixelbuffer_fastupload, to: CVPixelBuffer.self)
            setupCaptureDeviceResolution(resolution)
            detectFace(pixelBuffer: cvBuf)
        } else {
            // 自行构建 CVPixelBuffer 对象
            let pixelBuffer = frame.pointee.createPixelBuffer()
            setupCaptureDeviceResolution(resolution)
            guard let cvBuf = pixelBuffer else { return }
            detectFace(pixelBuffer: cvBuf)
        }
    }
}
```

在 `func videoProcessFrame(_ frame: UnsafeMutablePointer<VideoFrameYUV>!)` 的代理方法中，我们可以拿到 `VideoFrameYUV` 的数据。


理论上，在支持 HardwareDecode 的设备上，如果开启了 `HardwareDecode` 和 `Fastupload` , 返回的 `VideoFrameYUV` 里的 `luma`, `chromaB` and `chromaR` 可能会是空的(就无法构建 CVPixelBuffer)，这时候可以通过 `cv_pixelbuffer_fastupload` 获取到 `CVPixelBuffer` 的值。所以上面的代码里先判断 `frame.pointee.cv_pixelbuffer_fastupload` 是否不为 nil。

如果 cv_pixelbuffer_fastupload 为 nil 则我们需要自行构建 `CVPixelBuffer`，这里我们给 `VideoFrameYUV` 添加了一个扩展方法 `createPixelBuffer()` 以构建 `CVPixelBuffer`，这里就不贴代码了，具体可以查看 [Github](https://github.com/zyphs21/VisionDetect) 上的源码。

> 针对开启 HardwareDecode 获取到 cv_pixelbuffer_fastupload 的情况，目前我手头上的设备是无法获取得到，总是需要进行构建 CVPixelBuffer。这个问题在 [DJIWidget Github issue9](https://github.com/dji-sdk/DJIWidget/issues/9) 有相关的讨论。


## 二、把 CVPixelBuffer 传给 Vision 处理

Vision 对数据的处理逻辑可以分为三步：


| 做什么 | 怎么做 | 处理结果 |
| --- | --- | --- |
| VNRequest | VNImageRequestHandler<br/>VNSequenceRequestHandler | VNObservation |


#### 1. 做什么: 识别人脸及五官信息

为了识别人脸及其五官信息，我们需要创建 `VNDetectFaceLandmarksRequest`。

```Swift
let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)
```

#### 2. 怎么做: VNSequenceRequestHandler

因为我们需要处理视频流的一帧帧图片数据，所以我们用 `VNSequenceRequestHandler` 来执行 `FaceLandmarksRequest`。

```Swift
do {
    // 注意无人机图传中照片都是 downMirrored 的，即(0, 0)在左下角
    try sequenceRequestHandler.perform([detectFaceRequest], on: pixelBuffer, orientation: .downMirrored)
} catch {
    print("----执行 sequenceRequestHandler 失败: \(error.localizedDescription)")
}
```

调用 perform 方法时，除了传入要执行的 request 和 pixelBuffer 外，还需要注意传入图片的 Orientation 信息，以让 Vision 知道这个图片是倒着的还是反转的等等。因为我们的视频流是从无人机传过来的，这里测试发现都是 `downMirrored` 的，即照片的 (0, 0) 点在左下角。

#### 3. 处理结果：绘制人脸图层

最终得到的结果是封装在 `VNFaceObservation` 的对象里的，通过该对象可以拿到人脸相对于图片的坐标：`boundingBox` 以及五官的坐标信息 `landmarks`，从而可以绘制在图传界面上。具体绘制方法 `drawFaceObservations` 可以在 [Github](https://github.com/zyphs21/VisionDetect) 上查看。

```
func detectedFace(request: VNRequest, error: Error?) {
    if let error = error {
        print("---detectedFaceRequest Error: \(error.localizedDescription)")
        return
    }

    guard let results = request.results as? [VNFaceObservation] else { return }

    DispatchQueue.main.async {
        self.drawFaceObservations(results)
    }
}
```


## 总结

这里的关键点是在于：如何从无人机图传视频流里拿到 `CVPixelBuffer` ———— 这个 Vision 可以接受的数据。

另外一个的关键点是如何在图传界面上绘制出人脸信息，这里涉及到如何获取到视频图片的真实大小(Pixel单位)、ordination 等。

一旦处理好这些关键点，其余的问题就迎刃而解了。


> 欢迎关注我的公众号：HansonTalk
> ![](https://cdn.jsdelivr.net/gh/zyphs21/cdn-assets/qrcode/HansonTalk.jpg)
