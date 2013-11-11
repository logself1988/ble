//
//  BLDescriptorsViewController.m
//  ble-utility
//
//  Created by 北京锐和信科技有限公司 on 11/10/13.
//  Copyright (c) 2013 北京锐和信科技有限公司. All rights reserved.
//

#import "BLDescriptorsViewController.h"
#import "RKBlueKit.h"
#import "CBUUID+RKBlueKit.h"
#import "NSData+Hex.h"

@interface BLDescriptorsViewController ()<UITextFieldDelegate>

@end

@implementation BLDescriptorsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    __weak BLDescriptorsViewController * this = self;
    self.navigationItem.rightBarButtonItem = self.indicatorItem;
    [self.indicator startAnimating];
    [_peripheral discoverDescriptorsForCharacteristic:_characteristic onFinish:^(CBCharacteristic *characteristic, NSError *error) {
        [this.tableView reloadData];
        [this.indicator stopAnimating];
    }];
    
    //check if write supportted
    if ((_characteristic.properties &CBCharacteristicPropertyWrite) !=0 || (_characteristic.properties &CBCharacteristicPropertyWriteWithoutResponse) !=0)
    {
        self.valueTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.valueTextField.enabled = YES;
    }else
    {
        self.valueTextField.borderStyle = UITextBorderStyleNone;
        self.valueTextField.enabled = NO;
    }
    [self.peripheral readValueForCharacteristic:_characteristic onFinish:^(CBCharacteristic *characteristic, NSError *error) {
        this.valueTextField.text =[_characteristic.value hexadecimalString];
    }];
    if ((_characteristic.properties & CBCharacteristicPropertyRead)>0)
    {
        
    }
    //check  if notify
    if ((_characteristic.properties & CBCharacteristicPropertyNotify))
    {
        [self.peripheral setNotifyValue:YES forCharacteristic:self.characteristic onUpdated:^(CBCharacteristic *characteristic, NSError *error) {
            this.valueTextField.text =[characteristic.value hexadecimalString];
        }];
    }
    //labels
    self.properties.text =[ [RKBlueKit propertiesFrom: _characteristic.properties] componentsJoinedByString:@","];
    self.uuidLabel.text = [_characteristic.UUID representativeString];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewWillDisappear:(BOOL)animated
{
    //check  if notify
    if ((_characteristic.properties & CBCharacteristicPropertyNotify))
    {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.characteristic onUpdated:nil];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return _characteristic.descriptors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    CBDescriptor * descriptor = self.characteristic.descriptors[indexPath.row];
    UILabel * label = (UILabel*)[cell viewWithTag:19];
    label.text = [descriptor.UUID description];
    UILabel * uuidLabel = (UILabel *)[cell viewWithTag:20];
    [self.peripheral readValueForDescriptor:descriptor onFinish:^(CBDescriptor *tdescriptor, NSError *error) {
        uuidLabel.text =[NSString stringWithFormat:@"value:%@", tdescriptor.value];
    }];
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section ==0)
    {
        return [NSString stringWithFormat: @"%lu descriptors",(unsigned long)self.characteristic.descriptors.count];
    }
    return nil;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    __weak BLDescriptorsViewController * this = self;
    NSData * data = [NSData  dataWithHexString: textField.text ];
    if (data)
    {
        
        CBCharacteristicWriteType type =CBCharacteristicWriteWithResponse;
        RKCharacteristicChangedBlock onfinish=nil;
        if ((_characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) !=0)
        {
            type = CBCharacteristicWriteWithoutResponse;
        }else
        {
            [self.indicator startAnimating];
            onfinish = ^(CBCharacteristic * characteristic, NSError * error)
            {
                DebugLog(@"write response %@",error);
                [this.indicator stopAnimating];
                
                if (error)
                {
                    NSLog(@"%@",error);
                }else
                {
                    
                }
            };
        }
        [self.peripheral writeValue:data forCharacteristic:_characteristic type:type onFinish:onfinish];
    }
        [textField resignFirstResponder];
    return YES;
}

@end