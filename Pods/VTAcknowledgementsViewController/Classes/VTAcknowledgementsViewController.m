//
// VTAcknowledgementsViewController.m
//
// Copyright (c) 2013-2014 Vincent Tourraine (http://www.vtourraine.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VTAcknowledgementsViewController.h"
#import "VTAcknowledgementViewController.h"
#import "VTAcknowledgement.h"

static NSString *const VTDefaultAcknowledgementsPlistName = @"Pods-acknowledgements";
static NSString *const VTCocoaPodsURLString = @"http://cocoapods.org";
static const CGFloat VTLabelMargin          = 20;

@interface VTAcknowledgementsViewController ()

+ (NSString *)acknowledgementsPlistPathForName:(NSString *)name;
+ (NSString *)defaultAcknowledgementsPlistPath;
+ (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString;

- (void)configureHeaderView;
- (void)configureFooterView;

- (IBAction)dismissViewController:(id)sender;
- (void)commonInitWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath;
- (void)openCocoaPodsWebsite:(id)sender;

@end


@implementation VTAcknowledgementsViewController

+ (NSString *)acknowledgementsPlistPathForName:(NSString *)name
{
    return [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
}

+ (NSString *)defaultAcknowledgementsPlistPath
{
    return [self acknowledgementsPlistPathForName:VTDefaultAcknowledgementsPlistName];
}

+ (instancetype)acknowledgementsViewController
{
    NSString *path = self.defaultAcknowledgementsPlistPath;
    return [[self.class alloc] initWithAcknowledgementsPlistPath:path];
}

- (id)initWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self commonInitWithAcknowledgementsPlistPath:acknowledgementsPlistPath];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSString *path;
    if (self.acknowledgementsPlistName) {
        path = [self.class acknowledgementsPlistPathForName:self.acknowledgementsPlistName];
    }
    else {
        path = self.class.defaultAcknowledgementsPlistPath;
    }

    [self commonInitWithAcknowledgementsPlistPath:path];
}

- (void)commonInitWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath
{
    self.title = self.class.localizedTitle;    
    NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:acknowledgementsPlistPath];
    NSArray *preferenceSpecifiers = root[@"PreferenceSpecifiers"];
    if (preferenceSpecifiers.count >= 2) {
        // Remove the header and footer
        NSRange range = NSMakeRange(1, preferenceSpecifiers.count - 2);
        preferenceSpecifiers = [preferenceSpecifiers subarrayWithRange:range];
    }

    NSMutableArray *acknowledgements = [NSMutableArray array];
    for (NSDictionary *preferenceSpecifier in preferenceSpecifiers) {
        VTAcknowledgement *acknowledgement = [VTAcknowledgement new];
        acknowledgement.title = preferenceSpecifier[@"Title"];
        acknowledgement.text  = preferenceSpecifier[@"FooterText"];
        [acknowledgements addObject:acknowledgement];
    }

    [acknowledgements sortUsingComparator:^NSComparisonResult(VTAcknowledgement *obj1, VTAcknowledgement *obj2) {
        return [obj1.title compare:obj2.title
                           options:kNilOptions
                             range:NSMakeRange(0, obj1.title.length)
                            locale:[NSLocale currentLocale]];
    }];

    self.acknowledgements = acknowledgements;
}

#pragma mark - Localization

+ (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    static NSBundle *bundle = nil;
    if (!bundle) {
        NSString *bundlePath = [NSBundle.mainBundle pathForResource:@"VTAcknowledgementsViewController" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];

        NSString *language = NSLocale.preferredLanguages.count? NSLocale.preferredLanguages.firstObject: @"en";
        if (![bundle.localizations containsObject:language]) {
            language = [language componentsSeparatedByString:@"-"].firstObject;
        }
        if ([bundle.localizations containsObject:language]) {
            bundlePath = [bundle pathForResource:language ofType:@"lproj"];
        }

        bundle = [NSBundle bundleWithPath:bundlePath] ?: NSBundle.mainBundle;
    }

    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [NSBundle.mainBundle localizedStringForKey:key value:defaultString table:nil];
}

+ (NSString *)localizedTitle
{
    return [self localizedStringForKey:@"VTAckAcknowledgements" withDefault:@"Acknowledgements"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.headerText) {
        [self configureHeaderView];
    }

    [self configureFooterView];

    if (self.presentingViewController && self == [self.navigationController.viewControllers firstObject]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(dismissViewController:)];
    }
}

- (void)configureHeaderView
{
    UIFont *font = [UIFont fontWithName:@"ProximaNova-Light" size:12];
    CGFloat labelWidth = CGRectGetWidth(self.view.frame) - 2 * VTLabelMargin;
    CGFloat labelHeight;
    
    if ([self.headerText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSStringDrawingOptions options = (NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin);
        CGRect labelBounds = [self.headerText boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                           options:options
                                                        attributes:@{NSFontAttributeName: font}
                                                           context:nil];
        labelHeight = CGRectGetHeight(labelBounds);
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        CGSize size = [self.headerText sizeWithFont:font constrainedToSize:(CGSize){labelWidth, CGFLOAT_MAX}];
#pragma GCC diagnostic pop
        labelHeight = size.height;
    }


    CGRect labelFrame = CGRectMake(VTLabelMargin, VTLabelMargin, labelWidth, labelHeight);

    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text             = self.headerText;
    label.font             = font;
    label.textColor        = [UIColor grayColor];
    label.backgroundColor  = [UIColor clearColor];
    label.numberOfLines    = 0;
    label.textAlignment    = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);

    CGRect headerFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(label.frame) + 2 * VTLabelMargin);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    [headerView addSubview:label];
    self.tableView.tableHeaderView = headerView;
}

- (void)configureFooterView
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text             = [NSString stringWithFormat:@"%@\n%@",
                              [self.class localizedStringForKey:@"VTAckGeneratedByCocoaPods" withDefault:@"Generated by CocoaPods"],
                              VTCocoaPodsURLString];
    label.font             = [UIFont fontWithName:@"ProximaNova-Light" size:12];
    label.textColor        = [UIColor grayColor];
    label.backgroundColor  = [UIColor clearColor];
    label.numberOfLines    = 2;
    label.textAlignment    = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    label.userInteractionEnabled = YES;
    [label sizeToFit];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openCocoaPodsWebsite:)];
    [label addGestureRecognizer:tapGestureRecognizer];

    CGRect footerFrame = CGRectMake(0, 0, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame) + 3 * VTLabelMargin);
    UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
    footerView.userInteractionEnabled = YES;
    [footerView addSubview:label];
    label.frame = CGRectMake(0, VTLabelMargin, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));
    self.tableView.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow
                                  animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.acknowledgements.count == 0) {
        NSLog(@"** VTAcknowledgementsViewController Warning **");
        NSLog(@"No acknowledgements found.");
        NSLog(@"This probably means that you didn’t import the `Pods-acknowledgements.plist` to your main target.");
        NSLog(@"Please take a look at https://github.com/vtourraine/VTAcknowledgementsViewController for instructions.");
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (self.headerText) {
        [self configureHeaderView];
    }
}

#pragma mark - Actions

- (void)openCocoaPodsWebsite:(id)sender
{
    NSURL *URL = [NSURL URLWithString:VTCocoaPodsURLString];
    [[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.acknowledgements.count+2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    if (indexPath.row < self.acknowledgements.count) {
        VTAcknowledgement *acknowledgement = self.acknowledgements[indexPath.row];
        cell.textLabel.text = acknowledgement.title;
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    }else{
        if (indexPath.row == self.acknowledgements.count+1) {
            cell.textLabel.text = @"Magical Record";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        }else{
            cell.textLabel.text = @"Reachability";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
         }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.acknowledgements.count) {
        VTAcknowledgement *acknowledgement = self.acknowledgements[indexPath.row];
        VTAcknowledgementViewController *viewController = [[VTAcknowledgementViewController alloc] initWithTitle:acknowledgement.title text:acknowledgement.text];
        viewController.textViewFont = self.licenseTextViewFont;
        [self.navigationController pushViewController:viewController animated:YES];

    }else{
        if (indexPath.row == self.acknowledgements.count+1) {
            VTAcknowledgementViewController *viewController = [[VTAcknowledgementViewController alloc] initWithTitle:@"Magical Record" text:@""
                                                               "\nCopyright (c) 2010, Magical Panda Software, LLC"
                                                               "\n\nPermission is hereby granted, free of charge, to any person"
                                                               "\nobtaining a copy of this software and associated documentation"
                                                               "\nfiles (the \"Software\"), to deal in the Software without"
                                                               "\nrestriction, including without limitation the rights to use,"
                                                               "\ncopy, modify, merge, publish, distribute, sublicense, and/or sell"
                                                               "\ncopies of the Software, and to permit persons to whom the"
                                                               "\nSoftware is furnished to do so, subject to the following conditions:"
                                                               "\n\nThe above copyright notice and this permission notice shall be"
                                                               "\nincluded in all copies or substantial portions of the Software."
                                                               "\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,"
                                                               "\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES"
                                                               "\nOF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND"
                                                               "\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT"
                                                               "\nHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,"
                                                               "\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING"
                                                               "\nFROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR"
                                                               "\nOTHER DEALINGS IN THE SOFTWARE."
                                                               ""];
            viewController.textViewFont = self.licenseTextViewFont;
            [self.navigationController pushViewController:viewController animated:YES];
        }else{
            VTAcknowledgementViewController *viewController = [[VTAcknowledgementViewController alloc] initWithTitle:@"Reachability" text:@"\n"
                                                               "\nCopyright (c) 2011-2013, Tony Million."
                                                               "\nAll rights reserved."
                                                               "\nRedistribution and use in source and binary forms, with or without"
                                                               "\nmodification, are permitted provided that the following conditions are met:"
                                                               "\n\n1. Redistributions of source code must retain the above copyright notice, this"
                                                               "\nlist of conditions and the following disclaimer."
                                                               "\n\n2. Redistributions in binary form must reproduce the above copyright notice,"
                                                               "\nthis list of conditions and the following disclaimer in the documentation"
                                                               "\nand/or other materials provided with the distribution."
                                                               "\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\""
                                                               "\nAND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE"
                                                               "\nIMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE"
                                                               "\nARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE"
                                                               "\nLIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR"
                                                               "\nCONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF"
                                                               "\nSUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS"
                                                               "\nINTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN"
                                                               "\nCONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)"
                                                               "\nARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE"
                                                               "\nPOSSIBILITY OF SUCH DAMAGE."
                                                               ""];
            viewController.textViewFont = self.licenseTextViewFont;
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

@end

