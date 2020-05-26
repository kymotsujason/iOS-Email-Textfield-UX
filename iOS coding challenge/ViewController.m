//
//  ViewController.m
//  iOS coding challenge
//
//  Created by Jason Yue on 2018-09-16.
//

#import "ViewController.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
{
    // Regex strings
    NSString *emailRegex;
    NSString *extRegex;
    NSString *domainRegex;
    NSString *domainRegexAuto;
    NSString *extRegexAuto;
    NSString *extRegexSecondary;
    
    // Kickbox API
    NSString *apiKey;
    
    // Domain and suggestions array
    NSMutableArray *mutArr;
    NSArray *defaultDomains;
    NSArray *extDomains;
    
    // Predicates for regex matching
    NSPredicate *emailTest;
    NSPredicate *domainTest;
    NSPredicate *domainTestAuto;
    NSPredicate *extTest;
    NSPredicate *extTestAuto;
    NSPredicate *extTestSecondary;
}
@end


/**
 *  This is an email validator that checks the email address in real time.
 *  Any typos or mistakes are pointed out to the user right away.
 *  To help the user save time, the program will suggest a completed version of the email
 *  address after the user has entered a username and the @ symbol.
 *  If the user wants to specify a domain, the program will refine its suggestions based
 *  on the letters specified by the user after the @ symbol. The same will happen to the
 *  extensions.
 *  Once a valid email format has been detected, check with an API to make sure the email
 *  exists and is deliverable.
 *
 */
@implementation ViewController
@synthesize emailField, tblDropDown, tblDropDownHC, feedbackField;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Set the feedback and email field border for improved clarity
    //feedbackField.layer.borderWidth = 2.0f;
    
    tblDropDown.layer.borderWidth = 0.5f;
    tblDropDown.layer.borderColor = [UIColor blackColor].CGColor;
    
    // Initialize primary mutable array for displaying suggestions
    mutArr = [[NSMutableArray alloc]init];
    
    // Initialize values for validation, suggestions, and API calls
    [self initValidationModule];
    [self initSuggestionModule];
    [self initHTTPModule];
    
    // Delegate of tableview for suggestions
    [tblDropDown setDelegate:self];
    [tblDropDown setDataSource:self];
    self.tblDropDownHC.constant = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Init

/**
 *  @brief: This initializes variables used for email validation
 *
 *  @discussion: The validation functions are modularized and can be moved into a new file without too much
 *  trouble. To assist further, these are the variables used for the email validation functions.
 */
- (void)initValidationModule {
    // Regex validates the entire email format (eg. username@domain.ext)
    emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    
    // Regex validates the extension format (eg. username@domain.<ext>)
    extRegex = @"[A-Z0-9a-z._%+-]{1,64}+@[A-Za-z0-9-]{1,254}+\\.[A-Za-z]{1,4}";
    
    // Regex validates the domain format (eg. username@<domain>)
    domainRegex = @"[A-Z0-9a-z._%+-]{1,64}+@[A-Za-z0-9-]{1,254}";
    
    // Regex checks if user is at the domain portion of the email (eg. username@<domain>)
    domainRegexAuto = @"[A-Z0-9a-z._%+-]+@";
    
    // Regex checks if user is at the extension portion of the email (eg. username@domain.<ext>)
    extRegexAuto = @"[A-Z0-9a-z._%+-]{1,64}+@[A-Za-z0-9-]+\\.";
    
    // Regex checks if the user is at the extension portion of the email and has typed another period
    // indicating a dual extension (eg. username@domain.ext1.<ext2>
    extRegexSecondary = @"[A-Z0-9a-z._%+-]{1,64}+@[A-Za-z0-9-]{1,254}+\\.[A-Za-z.]{1,4}";
    
    // Initialize predicates
    emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    extTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", extRegex];
    domainTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", domainRegex];
    domainTestAuto = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", domainRegexAuto];
    extTestAuto = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", extRegexAuto];
    extTestSecondary = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", extRegexSecondary];
}

/**
 *  @brief: This initializes variables used for suggestions
 *
 *  @discussion: The suggestions functions are modularized and can be moved into a new file without too much
 *  trouble. To assist further, these are the variables used for the suggestions functions.
 */
- (void)initSuggestionModule {
    // Initialize all of the domains
    defaultDomains = [NSArray arrayWithObjects:@"yahoo", @"outlook", @"icloud", @"gmail", @"mail",
                      @"msn", @"telus", @"live", @"gmx", @"comcast", @"qq", @"sky", @"mac", @"aim",
                      @"ymail", @"aol", @"google", @"googlemail", @"verizon", @"rogers", @"me", @"inbox",
                      @"shaw", nil];
    
    extDomains = [NSArray arrayWithObjects:@"com", @"com.au", @"com.tw", @"ca", @"co.nz", @"co.uk",
                  @"de", @"fr", @"it", @"ru", @"net", @"org", @"edu", @"gov", @"jp", @"nl", @"kr",
                  @"se", @"eu", @"ie", @"co.il", @"us", @"at", @"be", @"dk", @"hk", @"es", @"gr",
                  @"ch", @"no", @"cz", @"in", @"net.au", @"info", @"biz", @"mil", @"co.jp", @"uk", nil];
}


/**
 *  @brief: This initializes variables used for HTTP requests
 *
 *  @discussion: The HTTP functions are modularized and can be moved into a new file without too much
 *  trouble. To assist further, these are the variables used for the HTTP functions.
 */
- (void)initHTTPModule {
    // Initialize API key
    apiKey = @"live_8dabf6d5fdb36c11c8d236993831c5aa59552f5df0df0725b8300180242573b4";
}

#pragma mark -
#pragma mark Delegates

// Limit the amount of suggestions to a healthy 5 or less
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (mutArr.count <= 5) {
        return [mutArr count] ;
    }
    else {
        return 5;
    }
}

// Initialize cells and set the text to the mutable array's text
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[[UITableViewCell alloc]init];
    cell.textLabel.text=[mutArr objectAtIndex:indexPath.row];
    return cell;
}

// Set the email field's text to the text the user selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tblDropDown cellForRowAtIndexPath:indexPath];
    emailField.text=cell.textLabel.text;
    
    // Check of the suggested email is valid and close the keyboard and suggestions
    NSArray *objectsToPass = [NSArray arrayWithObjects:(UITextField *)emailField, (NSMutableArray *)mutArr, nil];
    [mutArr removeAllObjects];
    [self isValidEmail:objectsToPass];
    [self updateTable];
    [emailField resignFirstResponder];
}

/**
 *  @brief: Reformats the suggestions table height and reloads the data for smooth user experience
 *
 *  @discussion: This method resizes the height of the constraint for the suggestions table to ensure it matches the
 *  amount of suggestions for smooth user experience. The constraint is reloaded as well as the suggestions data itself
 *  to provide the user with a interactive experience.
 */
- (void)updateTable {
    // Ensure the dropdown doesn't add more than 5 lines
    if ([mutArr count] <= 5) {
        self.tblDropDownHC.constant = 33.0 * [mutArr count];
    }
    else {
        self.tblDropDownHC.constant = 33.0 * 5;
    }
    
    [self.view setNeedsUpdateConstraints];
    [self.tblDropDown reloadData];
}

/**
 *  @brief: Sets the colors of the feedback field to red
 *
 *  @discussion: This method sets the email field border and feedback field text color to complimenting
 *  colors of red. For more accuracy, RGBA values are used.
 */
- (void)wrongColor {
    emailField.layer.borderColor = [UIColor colorWithRed:185.0/255.0f
                                                   green:0/255.0f
                                                    blue:0/255.0f
                                                   alpha:1.0f].CGColor;
    
    [feedbackField setTextColor:[UIColor colorWithRed:140.0/255.0f
                                                green:0/255.0f
                                                 blue:0/255.0f
                                                alpha:1.0f]];
}

/**
 *  @brief: Sets the colors of the feedback field to green
 *
 *  @discussion: This method sets the email field border and feedback field text color to complimenting
 *  colors of green. For more accuracy, RGBA values are used.
 */
- (void)rightColor {
    emailField.layer.borderColor = [UIColor colorWithRed:0/255.0f
                                                   green:185/255.0f
                                                    blue:0/255.0f
                                                   alpha:1.0f].CGColor;
    
    [feedbackField setTextColor:[UIColor colorWithRed:0.0/255.0f
                                                green:140/255.0f
                                                 blue:0/255.0f
                                                alpha:1.0f]];
}

#pragma mark -
#pragma mark Actions

/**
 *  @brief: If the user taps outside of the textfield, hide the keyboard and suggestions
 *
 *  @discussion: This is an event handler, which listens for the start of a touch. Once a touch
 *  event is initiated, the keyboard and suggestions are closed. This improves user experience.
 *
 *  @param touches Interaction between the user and the screen
 *  @param event This is the touch event
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
    tblDropDown.hidden = true;
}

/**
 *  @brief: Called every time a change is performed in the email text field
 *
 *  @discussion: This is an action connected to the "EditingChanged" event of the
 *  UITextField. Every time the user adds or removes a character, this is called.
 *  Once called, the suggestions is cleared to prepare for new suggestions and
 *  the email validation function is called. The suggestions is reloaded afterwards.
 *  In the case that the user has entered an email address that fits the email format,
 *  delay the function call to make sure the user has finished the email address.
 *
 *  @param sender This is the UITextField class itself
 *  @param event This is how the user interacted with the UI
 */
- (IBAction)emailFieldChanged:(UITextField *)sender forEvent:(UIEvent *)event {
    NSArray *objectsToPass = [NSArray arrayWithObjects:(UITextField *)sender, (NSMutableArray *)mutArr, nil];
    
    // If the user has entered a valid email address
    if ([emailTest evaluateWithObject:emailField.text]) {
        [mutArr removeAllObjects];
        
        // Cancel a previous delayed function call
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Create a new delayed function call
        [self performSelector:@selector(isValidEmail: ) withObject:(UITextField *)objectsToPass afterDelay:1.0f];
        [self updateTable];
    }
    // Check email for validity
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [mutArr removeAllObjects];
        [self isValidEmail:objectsToPass];
        [self updateTable];
    }
    
}

/**
 *  @brief: Called every time the user touches/taps on the email text field
 *
 *  @discussion: This is an action connected to the "Touch down" event of the
 *  UITextField. Every time the user touchs/taps the email text field, check if
 *  the suggestons are hidden. If it's hidden, show it again.
 *
 *  @param sender This is the UITextField class itself
 */
- (IBAction)touchDown:(UITextField *)sender {
    if ([emailField.text length] > 0 && [mutArr count] > 0) {
        if (tblDropDown.hidden) {
            tblDropDown.hidden = false;
        }
    }
}

#pragma mark -
#pragma mark Validation

/**
 *  @brief: Matches the text entered by the user to a regex to verify email format
 *
 *  @discussion: This method attempts to match the text currently typed by the user to
 *  a properly formatted email address. If it's a valid email format, sent to the API
 *  and then send for analysis to determine what feedback to display. If the email format
 *  is invalid, send the text to the invalidEmail function. If the user hasn't typed
 *  anything or has deleted what was typed, hide the suggestions.
 *
 *  @param objectArray This is the array holding the email field and suggestions array
 */
- (void)isValidEmail:(NSArray *)objectArray  {
    UITextField *emailField = [objectArray firstObject];
    NSMutableArray *mutArr = [objectArray lastObject];
    NSString *responseText = @"";
    
    // Verify format as <string>@<string>.<string between 2-4 length>
    BOOL verifyEmail = [emailTest evaluateWithObject:emailField.text];
    [self wrongColor];
    emailField.layer.borderWidth = 2.0f;
    
    if (verifyEmail) {
        NSDictionary *jsonData = [self verifyEmail:emailField.text];
        responseText = [self analyzeJSONData:jsonData suggestionsArray:mutArr];
    }
    else {
        // Hides the suggestions table if the text field is blank
        if ([emailField.text length] == 0) {
            tblDropDown.hidden = true;
            emailField.layer.borderWidth = 0.0f;
        }
        // Check for where the email is invalid
        else {
            tblDropDown.hidden = false;
            responseText = [self invalidEmail:emailField.text suggestionsArray:mutArr];
        }
    }
    
    feedbackField.text = responseText;
}

#pragma mark -
#pragma mark Suggestions

/**
 *  @brief: Matches the text entered by the user to multiple regex to determine missing portions of email format
 *
 *  @discussion: This method uses the many different regex types to determine where the user has made an error
 *  or if they are missing a part in the email format. Once a match has been found, a method is called
 *  that tells the user what's missing as well as suggests how to fix/complete the email format.
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *
 *  @return This returns text indicating an incomplete extension
 */
- (NSString *)invalidEmail:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr {
    BOOL resultExt = [extTest evaluateWithObject:emailText];
    BOOL resultDomain = [domainTest evaluateWithObject:emailText];
    BOOL resultDomainAuto = [domainTestAuto evaluateWithObject:emailText];
    BOOL resultExtAuto = [extTestAuto evaluateWithObject:emailText];
    BOOL resultExtSecondary = [extTestSecondary evaluateWithObject:emailText];
    NSString *responseText = @"";
    
    // Detect if the user has entered 2 dots right after one another or has empty space after a dot
    NSArray *userDomain = [emailText componentsSeparatedByString:@"."];
    int emptyStrings = 0;
    for (NSString *object in userDomain) {
        if ([object length] == 0) {
            emptyStrings++;
        }
    }
    
    // Make sure there are at least 2 empty strings, meaning an extra dot somewhere
    if (emptyStrings > 1) {
        responseText = @"Invalid use of dots!";
    }
    // Detect if the user has multiple spaces entered
    else if ([emailText componentsSeparatedByString:@" "].count > 1) {
        responseText = @"Invalid use of spaces!";
    }
    // Detect if the user has multiple @ symbols typed
    else if ([emailText componentsSeparatedByString:@"@"].count > 2) {
        responseText = @"Invalid use of @ symbols!";
    }
    // Auto suggests popular domains (eg. <yahoo.com>)
    else if (resultDomainAuto) {
        responseText = [self domainAutoComplete:emailText suggestionsArray:mutArr];
    }
    // Auto suggests a domain based on the user's refined query (eg. <y>ahoo.com)
    else if (resultDomain) {
        responseText = [self domainAutoSuggest:emailText suggestionsArray:mutArr defaultArray:defaultDomains];
    }
    // Auto suggests popular extensions (eg. yahoo.<com>)
    else if (resultExtAuto) {
        responseText = [self extAutoComplete:emailText suggestionsArray:mutArr];
    }
    // Auto suggests an extension based on the user's refined query (eg. <c>o.uk)
    else if (resultExt) {
        responseText = [self extAutoSuggest:emailText suggestionsArray:mutArr extArray:extDomains];
    }
    // Auto suggests a secondary extension based on the user's refined query(eg. co.<u>k)
    else if (resultExtSecondary) {
        responseText = [self ext2AutoSuggest:emailText suggestionsArray:mutArr extArray:extDomains];
    }
    // Catch unknown cases
    else {
        responseText = @"Incomplete email address!";
    }
    
    return responseText;
}

/**
 *  @brief: Adds suggestions for popular full domain names
 *
 *  @discussion: This method adds suggestions in the form of popular domain names, which the user
 *  can select to quickly autocomplete their email.
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *
 *  @return: This returns text indicating a missing domain
 */
- (NSString *)domainAutoComplete:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr {
    NSString *feedbackText = @"Missing a domain!";
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"outlook.com"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"gmail.com"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"yahoo.com"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"icloud.com"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"inbox.com"]];
    
    return feedbackText;
}

/**
 *  @brief: Adds suggestions for domain names based on the user's refined query
 *
 *  @discussion: This method adds suggestions in the form of a domain name with a popular extension attached by default.
 *  The suggestions change and update based on what the user currently has typed after the "@" symbol. An example
 *  is if the user types "username@g", the suggestion may be "username@gmail.com". In the case
 *  that there is only 1 suggestion left, multiple popular extensions are displayed instead.
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *  @param defaultDomains This is the array holding all the domains
 *
 *  @return This returns text indicating an incomplete domain
 */
- (NSString *)domainAutoSuggest:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr defaultArray:(NSArray *)defaultDomains {
    NSString *feedbackText = @"Incomplete domain!";
    NSArray *userDomain = [emailText componentsSeparatedByString:@"@"];
    NSString *matchedDomain;
    NSUInteger index = [[userDomain lastObject] length];
    
    // Go through the domains and match them to what the user has typed after the "@" symbol
    for (NSString *object in defaultDomains) {
        if ([object length] < index) {
            continue;
        }
        
        if ([[object substringToIndex:index] isEqualToString:[userDomain lastObject]]) {
            matchedDomain = [object substringFromIndex:index];
            [mutArr addObject:[NSString stringWithFormat: @"%@%@.com", emailText, [object substringFromIndex:index]]];
        }
    }
    
    if ([mutArr count] == 1) {
        [mutArr addObject:[NSString stringWithFormat: @"%@%@.%@", emailText, matchedDomain, @"co.uk"]];
        [mutArr addObject:[NSString stringWithFormat: @"%@%@.%@", emailText, matchedDomain, @"net"]];
        [mutArr addObject:[NSString stringWithFormat: @"%@%@.%@", emailText, matchedDomain, @"ca"]];
    }
    
    return feedbackText;
}

/**
 *  @brief: Adds suggestions for popular extensions
 *
 *  @discussion: This method adds suggestions in the form of popular extensions to the
 *  suggestions array, which is displayed for the user to select and autocomplete their email.
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *
 *  @return This returns text indicating a missing domain
 */
- (NSString *)extAutoComplete:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr {
    NSString *feedbackText = @"Missing the extension of the domain!";
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"com"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"co.uk"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"net"]];
    [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, @"ca"]];
    
    return feedbackText;
}

/**
 *  @brief: Adds suggestions for extensions based on the user's refined query
 *
 *  @discussion: This method adds suggestions in the form of an extension. The suggestions
 *  change and update based on what the user currently has typed after the "." character.
 *  An example is if the user types "username@gmail.", the suggestion may be "username@gmail.com".
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *  @param extDomains This is the array holding domain extensions
 *
 *  @return This returns text indicating an incomplete extension
 */
- (NSString *)extAutoSuggest:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr extArray:(NSArray *)extDomains {
    NSString *feedbackText = @"Incomplete extension!";
    NSArray *userDomain = [emailText componentsSeparatedByString:@"."];
    NSUInteger index = [[userDomain lastObject] length];
    
    // Go through the extensions and match them to what the user has typed after the "." character
    for (NSString *object in extDomains) {
        if ([object length] < index) {
            continue;
        }
        
        if ([[object substringToIndex:index] isEqualToString:[userDomain lastObject]]) {
            [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, [object substringFromIndex:index]]];
        }
    }
    
    return feedbackText;
}

/**
 *  @brief: Adds suggestions for secondary extensions based on the user's refined query
 *
 *  @discussion: This method adds suggestions in the form of a secondary extension. The suggestions change and
 *  update based on what the user currently has typed after the "." character and the first part of the extension.
 *  An example is if the user types "username@gmail.co.", the suggestion may be "username@gmail.co.uk".
 *
 *  @param emailText This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *  @param extDomains This is the array holding domain extensions
 *
 *  @return This returns text indicating an incomplete extension
 */
- (NSString *)ext2AutoSuggest:(NSString *)emailText suggestionsArray:(NSMutableArray *)mutArr extArray:(NSArray *)extDomains {
    NSString *feedbackText = @"Incomplete extension!!";
    NSArray *userDomain = [emailText componentsSeparatedByString:@"."];
    NSString *dualExt;
    NSUInteger index = [[userDomain lastObject] length];
    
    // Make sure the user has something typed for the first part of the extension and then concatenate the first part
    // with the second for more accurate matching
    if ([userDomain count] >= 2) {
        dualExt = [NSString stringWithFormat: @"%@.%@", userDomain[[userDomain count] - 2], [userDomain lastObject]];
        index = [userDomain[[userDomain count] - 2] length] + [[userDomain lastObject] length] + 1;
    }
    
    // Go through the extensions and match them to what the user has typed after the "." character
    for (NSString *object in extDomains) {
        if ([object length] < index) {
            continue;
        }
        
        if ([[object substringToIndex:index] isEqualToString:dualExt]) {
            [mutArr addObject:[NSString stringWithFormat: @"%@%@", emailText, [object substringFromIndex:index]]];
        }
    }
    
    return feedbackText;
}

#pragma mark -
#pragma mark HTTP

/**
 *  @brief: Sends the email to an API to determine whether the email exists
 *
 *  @discussion: This method uses the native session library and NSMutableURLRequest to send an HTTP GET
 *  request to the kickbox API using the current email address writen in the email field. Since the
 *  results are in JSON format, serialize the JSON data so we can read it later. Since this is an async
 *  request, use NSRunLoop to wait for it to complete.
 *
 *  @param emailText This is the current text in the email field
 *
 *  @return This returns a dictionary of serialized JSON data
 */
- (NSDictionary *)verifyEmail:(NSString *)emailText {
    __block NSDictionary *jsonData;
    // Use an autoreleasepool, since the request should not block the main thread, but also needs to not be dealloc'd immediately
    @autoreleasepool {
        // Set sessions
        NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
        
        // Set URL
        NSString *link = [NSMutableString stringWithFormat:@"https://api.kickbox.com/v2/verify?email=%@&apikey=%@", emailText, apiKey];
        NSURL *url = [NSURL URLWithString:link];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        
        // Set HTTP method as GET
        [urlRequest setHTTPMethod:@"GET"];
        
        __block BOOL done = false;
        
        // Fetches and downloads data to memory
        NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSError *errorCode = nil;
            // Set the block variable to hold onto the JSON data
            jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&errorCode];
            done = true;
        }];
        [dataTask resume];
        
        // Ensure that the request is finished
        while (!done) {
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:0.1];
            [[NSRunLoop currentRunLoop] runUntilDate:date];
        }
    }
    
    return jsonData;
}

/**
 *  @brief: Determines the status of the API query and output in a user friendly way
 *
 *  @discussion: This method takes the JSON data returned by the API query and matches it
 *  through a block dictionary to determine what feedback should be displayed. If a suggestion
 *  is available, it'll be displayed.
 *
 *  @param jsonData This is the current text in the email field
 *  @param mutArr This is the array holding the suggestions
 *
 *  @return This returns text indicating the status of the email
 */
- (NSString *)analyzeJSONData:(NSDictionary *)jsonData suggestionsArray:(NSMutableArray *)mutArr {
    __block NSString *responseText = @"";
    
    // Grab the JSON data by tags
    NSString *did_you_mean = jsonData[@"did_you_mean"];
    NSString *reason = jsonData[@"reason"];
    BOOL success = jsonData[@"success"];
    
    // In the small chance that the API is down (doesn't respond)
    if (!success) {
        responseText = @"API seems to be down...";
    }
    // Use a block dictionary for fast matching to determine what to tell the user
    else {
        void (^selectCase)(void) = @{
                                     @"invalid_email": ^{
                                         responseText = @"Invalid email format!";
                                     },
                                     @"invalid_domain": ^{
                                         responseText = @"Domain does not exist!";
                                     },
                                     @"rejected_email": ^{
                                         responseText = @"Email does not exist!";
                                     },
                                     @"accepted_email": ^{
                                         [self rightColor];
                                         responseText = @"Valid email!";
                                     },
                                     @"low_quality": ^{
                                         [self rightColor];
                                         responseText = @"Valid email!";
                                     },
                                     @"low_deliverability": ^{
                                         [self rightColor];
                                         responseText = @"Valid email!";
                                     },
                                     @"no_connect": ^{
                                         responseText = @"Error, mail server offline!";
                                     },
                                     @"timeout": ^{
                                         responseText = @"Error, mail server offline!";
                                     },
                                     @"invalid_smtp": ^{
                                         responseText = @"Error, mail server offline!";
                                     },
                                     @"unavailable_smtp": ^{
                                         responseText = @"Error, mail server offline!";
                                     },
                                     @"unexpected_error": ^{
                                         responseText = @"Something went wrong...";
                                     },
                                     }[reason];
        
        selectCase();
        
        // If there are any suggestions from the API, show it
        if (![did_you_mean isEqual:[NSNull null]]) {
            [mutArr addObject:did_you_mean];
        }
    }
    
    return responseText;
}

@end
