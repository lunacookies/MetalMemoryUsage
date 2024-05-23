@interface MainView : NSView <CALayerDelegate>
@end

@implementation MainView

id<MTLDevice> device;
CAMetalLayer *metalLayer;
id<MTLCommandQueue> commandQueue;
CVDisplayLinkRef displayLink;
id<MTLRenderPipelineState> pipelineState;

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];

	self.wantsLayer = YES;
	self.layer = [CAMetalLayer layer];
	device = MTLCreateSystemDefaultDevice();
	metalLayer = (CAMetalLayer *)self.layer;
	metalLayer.device = device;
	metalLayer.delegate = self;
	metalLayer.maximumDrawableCount = 2;

	commandQueue = [device newCommandQueue];

	NSBundle *bundle = [NSBundle mainBundle];
	NSURL *libraryURL = [bundle URLForResource:@"shaders" withExtension:@"metallib"];
	id<MTLLibrary> library = [device newLibraryWithURL:libraryURL error:nil];

	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexFunction"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentFunction"];
	pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, DisplayLinkCallback, (__bridge void *)self);
	CVDisplayLinkStart(displayLink);
	return self;
}

- (void)displayLayer:(CALayer *)layer
{
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
	id<CAMetalDrawable> drawable = [metalLayer nextDrawable];

	MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
	descriptor.colorAttachments[0].texture = drawable.texture;
	descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder setRenderPipelineState:pipelineState];
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
	[encoder endEncoding];

	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}

- (void)viewDidChangeBackingProperties
{
	[super viewDidChangeBackingProperties];
	metalLayer.contentsScale = self.window.backingScaleFactor;
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	float scaleFactor = (float)self.window.backingScaleFactor;
	size.width *= scaleFactor;
	size.height *= scaleFactor;
	metalLayer.drawableSize = size;
}

static CVReturn
DisplayLinkCallback(CVDisplayLinkRef _displayLink, const CVTimeStamp *inNow,
        const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut,
        void *context)
{
	MainView *view = (__bridge MainView *)context;
	dispatch_sync(dispatch_get_main_queue(), ^{
	  [view.layer setNeedsDisplay];
	});
	return kCVReturnSuccess;
}

@end
