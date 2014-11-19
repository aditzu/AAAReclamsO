//
//  SecondViewController.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 10/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self splitPdf];
}

-(void) splitPdf
{
    //"fileURL" is the original File which has to be broken
    //"pages" is the number of pages in PDF
    NSString* fileURL = [[NSBundle mainBundle] pathForResource:@"kaufland" ofType:@"pdf"];
    NSURL* localPdfFile = [[NSURL alloc] initFileURLWithPath:fileURL];
    CFURLRef urlRef = (__bridge CFURLRef) localPdfFile;
    CGPDFDocumentRef docRef = CGPDFDocumentCreateWithURL(urlRef);
    NSInteger pages = CGPDFDocumentGetNumberOfPages(docRef);
    
    for (int page = 1; page <= pages; page++)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *dirName = [basePath stringByAppendingPathComponent:@"/CreatedPDF"];
        [fm createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *pdfPath = [dirName stringByAppendingPathComponent:[NSString stringWithFormat:@"page_%d.pdf",page]];
        NSURL *pdfUrl = [NSURL fileURLWithPath:pdfPath];
        
        CGContextRef context = CGPDFContextCreateWithURL((__bridge_retained CFURLRef)pdfUrl, NULL, NULL);
        
        CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((__bridge_retained CFURLRef)localPdfFile);
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDoc, page);
        CGRect pdfCropBoxRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
        
        // Copy the page to the new document
        CGContextBeginPage(context, &pdfCropBoxRect);
        CGContextDrawPDFPage(context, pdfPage);
        // Close the source files
        CGContextEndPage(context);
        CGPDFDocumentRelease(pdfDoc);
        CGContextRelease(context);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
