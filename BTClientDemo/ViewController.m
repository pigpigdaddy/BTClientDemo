//
//  ViewController.m
//  BTClientDemo
//
//  Created by pigpigdaddy on 14-8-21.
//  Copyright (c) 2014年 pigpigdaddy. All rights reserved.
//

static NSString * const kServiceUUID = @"5845C0AF-F55D-43BE-B20A-B4443664F3CE";
static NSString * const kCharacteristicUUID = @"F5C0119C-84A6-4B53-9DF4-1189192107D2";

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel *labelStatus;
@property (nonatomic, strong) UILabel *labelReceiveData;

@property (nonatomic, strong)UIButton *btnStart;


@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    self.labelStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, 320, 50)];
    self.labelStatus.font = [UIFont systemFontOfSize:22];
    self.labelStatus.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.labelStatus];
    self.labelStatus.text = @"正在搜寻周边......";
    
    self.labelReceiveData = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 320, 50)];
    self.labelReceiveData.font = [UIFont systemFontOfSize:22];
    self.labelReceiveData.textAlignment = NSTextAlignmentCenter;
    self.labelReceiveData.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.labelReceiveData];
    
    self.btnStart = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnStart.frame = CGRectMake(100, 200, 120, 40);
    [self.btnStart setTitle:@"重新启动服务" forState:UIControlStateNormal];
    [self.btnStart addTarget:self action:@selector(startbuttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnStart];
}

- (void)startbuttonAction:(id)sender
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark
#pragma mark ============ CBCentralManagerDelegate ============
// 更新状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
            case CBCentralManagerStatePoweredOn:
        {
            // 搜索周边的一个服务 kServiceUUID
            [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            self.labelStatus.text = @"正在搜寻服务......";
        }
            break;
            
        default:
        {
            NSLog(@"Central Manager did change state");
        }
            break;
    }
}

// 发现了一个周边 包含了数据和信号质量
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // 搜到以后就停止搜索
    [self.centralManager stopScan];
    
    if (self.peripheral != peripheral) {// 连接
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        
        [self.centralManager connectPeripheral:peripheral options:nil];
        self.labelStatus.text = @"发现了一个周边，正在尝试连接......";
    }
}

// 成功连接了周边
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"蓝牙信息" message:@"恭喜!连接周边设备成功!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    // Clears the data that we may already have
    [self.data setLength:0];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
    
    // 去发现服务
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
    self.labelStatus.text = @"成功连接周边，正在发现服务......";
}

// 连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"蓝牙信息" message:@"抱歉!连接周边设备失败!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    self.labelStatus.text = [NSString stringWithFormat:@"发生错误:%@", error];
}

// 发现服务结果回调
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        // 发现服务错误
        NSLog(@"Error discovering service:%@", [error localizedDescription]);
        self.labelStatus.text = [NSString stringWithFormat:@"发现服务错误:%@", error];
        return;
    }
    
    // 发现了服务
    for (CBService *service in aPeripheral.services) {
        NSLog(@"Service found with UUID: %@", service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]])
        {
            // 发现了制定的服务 再去发现该服务的某个特征
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
            self.labelStatus.text = @"成功发现服务，正在发现特征......";
        }
    }
}

// 发现特征结果回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        // 发现特征错误
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        self.labelStatus.text = [NSString stringWithFormat:@"发现特征错误:%@", error];
        return;
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        for (CBCharacteristic *character in service.characteristics)
        {
            if ([character.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                NSLog(@"Successfully Found the Character I wanted!!!");
                [peripheral setNotifyValue:YES forCharacteristic:character];
                self.labelStatus.text = @"发现特征成功";
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    // Exits if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        return;
    }
              
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@. Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        self.labelStatus.text = [NSString stringWithFormat:@"更新特征数据错误:%@", error];
        return;
    }
    self.labelStatus.text = @"更新特征数据成功";
    self.labelReceiveData.text = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
}

@end