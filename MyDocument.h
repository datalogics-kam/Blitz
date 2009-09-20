#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class BlitzPDFView;

@interface MyDocument : NSDocument <QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
	IBOutlet BlitzPDFView *pdfView;
	@private PDFDocument *pdfDocument;
	@private NSTimer *timer;
    @private BOOL isInFullScreenMode;
    
    QLPreviewPanel *previewPanel;
    
    NSUInteger pageIndex;
}

@property (retain, nonatomic) IBOutlet BlitzPDFView *pdfView;
@property (readwrite) NSUInteger pageIndex;

@end
