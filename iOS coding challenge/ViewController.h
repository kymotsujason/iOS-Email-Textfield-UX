//
//  ViewController.h
//  iOS coding challenge
//
//  Created by Jason Yue on 2018-09-16.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(weak, nonatomic) IBOutlet UITextField *emailField;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *tblDropDownHC;
@property(weak, nonatomic) IBOutlet UITextField *feedbackField;
@property(weak, nonatomic) IBOutlet UITableView *tblDropDown;
- (IBAction)emailFieldChanged:(UITextField *)sender forEvent:(UIEvent *)event;
- (IBAction)touchDown:(UITextField *)sender;

@end
