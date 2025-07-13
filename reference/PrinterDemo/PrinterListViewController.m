//
//  PrinterListViewController.m
//  ZiJiangPrinterDemo
//
//  Created by aduo on 6/3/16.
//
//

#import "PrinterListViewController.h"
#import "PrinterSDK.h"


@interface PrinterListViewController ()
{
    IBOutlet UITableView* _tableView;
    
    NSMutableArray* _printerArray;
}

@end

@implementation PrinterListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"SelectPrinter", @"SelectPrinter");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[PrinterSDK defaultPrinterSDK] scanPrintersWithCompletion:^(Printer* printer)
    {
        if (nil == _printerArray)
        {
            _printerArray = [[NSMutableArray alloc] initWithCapacity:1];
        }
        
        [_printerArray addObject:printer];
        [_tableView reloadData];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[PrinterSDK defaultPrinterSDK] stopScanPrinters];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - table delegate and data source

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return _printerArray.count;
}

/***********************************************************************
 * 方法名称： cellForRowAtIndexPath
 * 功能描述： 获取cell视图
 * 输入参数： indexPath  位置信息
 * 输出参数：
 * 返回值：   cell  视图
 ***********************************************************************/
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* identify = @"PrinterCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identify];
    
    UILabel* nameLabel = [cell.contentView viewWithTag:1];
    UILabel* uuidLabel = [cell.contentView viewWithTag:2];
    
    Printer* printer = [_printerArray objectAtIndex:indexPath.row];
    nameLabel.text = printer.name;
    uuidLabel.text = printer.UUIDString;
    
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Printer* printer = [_printerArray objectAtIndex:indexPath.row];
    [[PrinterSDK defaultPrinterSDK] connectBT:printer];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
