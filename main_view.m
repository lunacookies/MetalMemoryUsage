@interface MainView : NSView
@end

@implementation MainView

id<MTLDevice> device;
id<MTLCommandQueue> commandQueue;
CVDisplayLinkRef displayLink;
id<MTLRenderPipelineState> pipelineState;

IOSurfaceRef framebufferSurface;
id<MTLTexture> framebuffer;

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.wantsLayer = YES;

	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	NSBundle *bundle = [NSBundle mainBundle];
	NSURL *libraryURL = [bundle URLForResource:@"shaders" withExtension:@"metallib"];
	id<MTLLibrary> library = [device newLibraryWithURL:libraryURL error:nil];

	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexFunction"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentFunction"];
	pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, DisplayLinkCallback, (__bridge void *)self);
	CVDisplayLinkStart(displayLink);
	return self;
}

- (void)render
{
	if (framebuffer == 0)
	{
		return;
	}

	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
	descriptor.colorAttachments[0].texture = framebuffer;
	descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder setRenderPipelineState:pipelineState];
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
	[encoder endEncoding];

	[commandBuffer commit];
	[commandBuffer waitUntilCompleted];
	self.layer.contents = (__bridge id)framebufferSurface;
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	size = [self convertSizeToBacking:self.frame.size];

	if (framebufferSurface != 0)
	{
		CFRelease(framebufferSurface);
	}

	NSDictionary *properties = @{
		(__bridge NSString *)kIOSurfaceWidth : @(size.width),
		(__bridge NSString *)kIOSurfaceHeight : @(size.height),
		(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		(__bridge NSString *)kIOSurfacePixelFormat : @(kCVPixelFormatType_32BGRA),
	};
	framebufferSurface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);

	MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.width = (NSUInteger)size.width;
	descriptor.height = (NSUInteger)size.height;
	descriptor.usage = MTLTextureUsageRenderTarget;
	descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
	framebuffer = [device newTextureWithDescriptor:descriptor
	                                     iosurface:framebufferSurface
	                                         plane:0];
}

static CVReturn
DisplayLinkCallback(CVDisplayLinkRef _displayLink, const CVTimeStamp *inNow,
        const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut,
        void *context)
{
	MainView *view = (__bridge MainView *)context;
	dispatch_sync(dispatch_get_main_queue(), ^{
	  [view render];
	});
	return kCVReturnSuccess;
}

@end
