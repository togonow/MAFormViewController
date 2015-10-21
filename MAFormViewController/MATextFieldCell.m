//
//  MATextFieldCell.m
//  MATextFieldCell Example
//
//  Created by Mike on 7/12/14.
//  Copyright (c) 2014 Mike Amaral. All rights reserved.
//

#import "MATextFieldCell.h"

static NSString * const kNextButtonText = @"Next";
static NSString * const kDoneButtonText = @"Done";

static CGFloat const kTextFieldVerticalPadding = 7.0;
static CGFloat const kTextFieldHorizontalPadding = 10.0;
static CGFloat const kToolbarHeight = 50.0;
static CGFloat const kPlaceHolderLabelFontSize = 14;
static CGFloat const kPlaceholderLabelFrameHeight = 18;
static CGFloat const kPlaceholderLabelAnimationDuration = 0.3;
static CGFloat const kDefaultSuggestedHeight = 44;
static CGFloat const kHeightIfUsingAnimatedPlaceholder = 55;

@implementation MATextFieldCell{
    NSArray *statesNameAbbreviationsArray;
}

- (instancetype)initWithFieldType:(enum MATextFieldType)type action:(enum MATextFieldActionType)action animatePlaceholder:(BOOL)animate actionHandler:(void (^)(void))handler {
    statesNameAbbreviationsArray = [self setupStatesNamesAbbreviationArray];
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _selectedEntry = nil;
    _type = type ?: MATextFieldTypeDefault;
    _action = action ?: MATextFieldActionTypeNone;
    _actionHandler = handler ?: ^{};
    _shouldAttemptFormat = YES;
    _animatePlaceholder = animate;
    if(_type == MATextFieldTypeStateDropDownList){
        _suggestedHeight = 150;
    }else{
        _suggestedHeight = (animate ? kHeightIfUsingAnimatedPlaceholder : kDefaultSuggestedHeight);
    }

    
    [self configureTextField];
    
    return self;
}


#pragma mark - Text field configuration

- (void)configureTextField {
    self.pickerField = [UIPickerView new];    self.textField = [UITextField new]; self.titleLabel = [UILabel new];

    CGRect frame = _animatePlaceholder ? CGRectMake(kTextFieldHorizontalPadding, CGRectGetHeight(self.contentView.frame) * .33, CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding), CGRectGetHeight(self.contentView.frame) * .66) : CGRectMake(kTextFieldHorizontalPadding, kTextFieldVerticalPadding, CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding), CGRectGetHeight(self.contentView.frame) - (2 * kTextFieldVerticalPadding));
    self.textField.frame = frame;
    
    CGRect pickerFrame = _animatePlaceholder ?
    
        CGRectMake(
        //X
        kTextFieldHorizontalPadding + 150
        // Y
        , _suggestedHeight * .33
        // W
       , CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding)
       // H
       , _suggestedHeight * .66)
    
    : CGRectMake(
        //X
        kTextFieldHorizontalPadding + 150
       // Y
       , kTextFieldVerticalPadding
       // W
       , CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding)
       // H
       , _suggestedHeight - (2 * kTextFieldVerticalPadding));
    
//    frame.size.height = 150; frame.origin.y = frame.origin.y - 5; frame.origin.x = frame.origin.x + 20;
    self.titleLabel.frame = frame;
    self.pickerField.frame = pickerFrame;   // setup the frame for the selectedState
    self.textField.delegate = self;
    self.pickerField.dataSource = self  ; self.pickerField.delegate = self;
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleHeight + UIViewAutoresizingFlexibleWidth;
    self.pickerField.autoresizingMask = UIViewAutoresizingFlexibleHeight + UIViewAutoresizingFlexibleWidth;

    
    BOOL requiresToolbar = NO;
    // based on the type of the field, we want to format the textfield according
    // to the most user-friendly conventions. Any of these values can be overridden
    // later if users want to customize further. Any of the fields with numeric keyboard
    // types require a toolbar to handle the next/done functionality
    switch (_type) {
        case MATextFieldTypeDefault:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            self.textField.autocorrectionType = UITextAutocorrectionTypeYes;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        case MATextFieldTypeName:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        case MATextFieldTypePhone:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            [self.textField addTarget:self action:@selector(formatPhoneNumber) forControlEvents:UIControlEventEditingChanged];
            requiresToolbar = YES;
            break;
        case MATextFieldTypeEmail:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case MATextFieldTypeAddress:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            self.textField.autocorrectionType = UITextAutocorrectionTypeYes;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        case MATextFieldTypeStateAbbr:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        case MATextFieldTypeZIP:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            requiresToolbar = YES;
            break;
        case MATextFieldTypeNumber:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            requiresToolbar = YES;
            break;
        case MATextFieldTypeDecimal:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeDecimalPad;
            requiresToolbar = YES;
            break;
        case MATextFieldTypeDate:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            [self.textField addTarget:self action:@selector(formatDate) forControlEvents:UIControlEventEditingChanged];
            requiresToolbar = YES;
            break;
        case MATextFieldTypePassword:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            self.textField.secureTextEntry = YES;
            break;
        case MATextFieldTypeURL:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeURL;
            break;
        case MATextFieldTypeNonEditable:
            [self.contentView addSubview:self.textField];
            self.textField.enabled = NO;
            break;
        case MATextFieldTypeSubDomain:
            [self.contentView addSubview:self.textField];
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeURL;
            [self.textField addTarget:self action:@selector(formatSubDomain) forControlEvents:UIControlEventEditingChanged];
            
            requiresToolbar = YES;
            break;
        case MATextFieldTypeStateDropDownList:
            [self.contentView addSubview:self.pickerField]; [self.contentView addSubview:self.titleLabel];
            self.textField.hidden = true ; self.pickerField.hidden = false;
            self.pickerField.dataSource = self;
            break;
    }
    
    
    
    
    // if any of the fields require a toolbar, set up the toolbar with the appropriate title,
    // otherwise set the appropriate return key type on the keyboard
    switch (_action) {
        case MATextFieldActionTypeNone:
            self.textField.returnKeyType = UIReturnKeyDefault;
            break;
        case MATextFieldActionTypeNext:
            if (requiresToolbar) {
                [self setupToolbarWithButtonTitle:kNextButtonText];
            }
            else {
                self.textField.returnKeyType = UIReturnKeyNext;
            }
            break;
        case MATextFieldActionTypeDone:
            if (requiresToolbar) {
                [self setupToolbarWithButtonTitle:kDoneButtonText];
            }
            else {
                self.textField.returnKeyType = UIReturnKeyDone;
            }
            break;
    }
}

- (void)setInitialValue:(NSString *)initialValue placeholder:(NSString *)placeholder {
    self.textField.placeholder = placeholder;
    self.titleLabel.text = placeholder;

    if (initialValue) {
        self.textField.text = initialValue;

        [self animatePlaceholderAbove];
    }
}


#pragma mark - placeholder animation

- (void)animatePlaceholderAbove {
    _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(kTextFieldHorizontalPadding, kTextFieldVerticalPadding, CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding), CGRectGetHeight(self.contentView.frame) - (2 * kTextFieldVerticalPadding))];
    _placeholderLabel.text = self.textField.placeholder;
    _placeholderLabel.font = [UIFont systemFontOfSize:kPlaceHolderLabelFontSize];
    _placeholderLabel.textColor = [UIColor lightGrayColor];
    _placeholderLabel.alpha = 0.0;
    
    [self addSubview:_placeholderLabel];
    CGRect originalFrame = _placeholderLabel.frame;
    
    [UIView animateWithDuration:kPlaceholderLabelAnimationDuration animations:^{
        _placeholderLabel.frame = CGRectMake(CGRectGetMinX(originalFrame), CGRectGetMinY(originalFrame) - 4, CGRectGetWidth(originalFrame), kPlaceholderLabelFrameHeight);
        _placeholderLabel.textColor = [UIColor blueColor];
        _placeholderLabel.alpha = 1.0;
    }];
}

- (void)animatePlaceholderBack {
    [UIView animateWithDuration:kPlaceholderLabelAnimationDuration animations:^{
        _placeholderLabel.frame = CGRectMake(kTextFieldHorizontalPadding, kTextFieldVerticalPadding, CGRectGetWidth(self.contentView.frame) - (2 * kTextFieldHorizontalPadding), CGRectGetHeight(self.contentView.frame) - (2 * kTextFieldVerticalPadding));
        _placeholderLabel.textColor = [UIColor lightGrayColor];
        _placeholderLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_placeholderLabel removeFromSuperview];
        _placeholderLabel = nil;
    }];
}


#pragma mark - Toolbar setup

- (void)setupToolbarWithButtonTitle:(NSString *)title {
    // create the toolbar and use a flexible space button to right-mount the action button, and point it towards the function
    // that will call the action block
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), kToolbarHeight)];
    UIBarButtonItem *flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(handleToolbarButtonPressed)];
    [toolbar setItems:@[flexibleSpaceButton, actionButton]];
    self.textField.inputAccessoryView = toolbar;
    
}

- (void)handleToolbarButtonPressed {
    _actionHandler();
}


#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    _actionHandler();
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // flag to determine if we are going to want to change characters in range
    BOOL shouldAllowEditing = NO;
    
    switch (_type) {
        // the state abbreviation cell should only allow two characters
        case MATextFieldTypeStateAbbr: {
            shouldAllowEditing = resultString.length < 3;
            break;
        }
            
        // the ZIP cell should only allow 5 characters
        case MATextFieldTypeZIP: {
            shouldAllowEditing = resultString.length < 6;
            break;
        }
            
        // we want to flag that we should attempt to format the phone number as long as they are adding characters...
        // if they are deleting characters ignore it and don't attempt to format
        case MATextFieldTypePhone: {
            _shouldAttemptFormat = resultString.length > self.textField.text.length;
            shouldAllowEditing = YES;
            break;
        }
            
        case MATextFieldTypeDate: {
            _shouldAttemptFormat = resultString.length > self.textField.text.length;
            shouldAllowEditing = resultString.length <= 10;
            break;
        }
         
        // otherwise let them do whatever they want
        default: {
            shouldAllowEditing = YES;
            break;
        }
    }
    
    // if we're going to allow edits to be made
    if (shouldAllowEditing) {
        // tell our delegate that there have been edits made to the form
        [self.delegate markFormHasBeenEdited];
        
        // if we want to animate the placeholder
        if (_animatePlaceholder) {
            // animate it if we're adding characters and we don't already have a placeholder label
            if (!_placeholderLabel && resultString.length > 0) {
                [self animatePlaceholderAbove];
            }
            
            // animate it back if we have a placeholder label and the resulting string will be empty
            else if (_placeholderLabel && resultString.length == 0) {
                [self animatePlaceholderBack];
            }
        }
    }
    
    return shouldAllowEditing;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // when we start editing again, update the placeholder label color to the active state
    if (_placeholderLabel) {
        _placeholderLabel.textColor = [UIColor blueColor];
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    // when we end editing, update the placeholder label color to the inactive state
    if (_placeholderLabel) {
        _placeholderLabel.textColor = [UIColor lightGrayColor];
    }
    
    return YES;
}


#pragma mark - SubDomain formatting
-(void)formatSubDomain{
    // this value is determined when textField shouldChangeCharactersInRange is called on a phone
    // number cell - if a user is deleting characters we don't want to try to format it, otherwise
    // using the current logic below certain deletions will have no effect
    if (!_shouldAttemptFormat) {
        return;
    }
    NSString *domainname = @"togonow.menu";
    NSString *currentString = self.textField.text;
    NSString *strippedValue = [currentString stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, currentString.length)];
    _placeholderLabel.text = [NSString stringWithFormat:@"http://%@.%@",strippedValue, domainname];
    self.textField.text = strippedValue;
    
}

#pragma mark - phone number formatting

- (void)formatPhoneNumber {
    // this value is determined when textField shouldChangeCharactersInRange is called on a phone
    // number cell - if a user is deleting characters we don't want to try to format it, otherwise
    // using the current logic below certain deletions will have no effect
    if (!_shouldAttemptFormat) {
        return;
    }
    
    // here we are leveraging some of the objective-c NSString functions to help parse and modify
    // the phone number... first we strip anything that's not a number from the textfield, and then
    // depending on the current value we append formatting characters to make it pretty
    NSString *currentString = self.textField.text;
    NSString *strippedValue = [currentString stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, currentString.length)];

    NSString *formattedString;
    if (strippedValue.length == 0) {
        formattedString = @"";
    }
    else if (strippedValue.length < 3) {
        formattedString = [NSString stringWithFormat:@"(%@", strippedValue];
    }
    else if (strippedValue.length == 3) {
        formattedString = [NSString stringWithFormat:@"(%@) ", strippedValue];
    }
    else if (strippedValue.length < 6) {
        formattedString = [NSString stringWithFormat:@"(%@) %@", [strippedValue substringToIndex:3], [strippedValue substringFromIndex:3]];
    }
    else if (strippedValue.length == 6) {
        formattedString = [NSString stringWithFormat:@"(%@) %@-", [strippedValue substringToIndex:3], [strippedValue substringFromIndex:3]];
    }
    else if (strippedValue.length <= 10) {
        formattedString = [NSString stringWithFormat:@"(%@) %@-%@", [strippedValue substringToIndex:3], [strippedValue substringWithRange:NSMakeRange(3, 3)], [strippedValue substringFromIndex:6]];
    }
    else if (strippedValue.length >= 11) {
        formattedString = [NSString stringWithFormat:@"(%@) %@-%@ x%@", [strippedValue substringToIndex:3], [strippedValue substringWithRange:NSMakeRange(3, 3)], [strippedValue substringWithRange:NSMakeRange(6, 4)], [strippedValue substringFromIndex:10]];
    }
    
    self.textField.text = formattedString;
}


#pragma mark - date formatting

- (void)formatDate {
    if (!_shouldAttemptFormat) {
        return;
    }
    
    NSString *currentString = self.textField.text;
    NSString *strippedValue = [currentString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, currentString.length)];
    
    // Date formatting will follow the format MM/DD/YYYY
    NSString *formattedString;
    if (strippedValue.length == 0) {
        formattedString = @"";
    }
    else if (strippedValue.length < 2) {
        formattedString = strippedValue;
    }
    else if (strippedValue.length == 2) {
        formattedString = [NSString stringWithFormat:@"%@/", strippedValue];
    }
    else if (strippedValue.length <= 4) {
        formattedString = [NSString stringWithFormat:@"%@/%@", [strippedValue substringToIndex:2], [strippedValue substringFromIndex:2]] ;
    }
    else if (strippedValue.length <= 8) {
        formattedString = [NSString stringWithFormat:@"%@/%@/%@", [strippedValue substringToIndex:2], [strippedValue substringWithRange:NSMakeRange(2, 2)], [strippedValue substringFromIndex:4]] ;
    }
    else {
        formattedString = currentString;
    }
    
    self.textField.text = formattedString;
}


#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return statesNameAbbreviationsArray.count + 1;
}

-(void) pickerView:(UIPickerView*) pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    _selectedEntry = (row == 0 ? nil    :  statesNameAbbreviationsArray[row -1]);
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return  (row == 0 ? @"Pick a State" :    statesNameAbbreviationsArray[row]);
}

-(NSArray*) setupStatesNamesAbbreviationArray{
    return [NSArray arrayWithObjects:@"Alabama", @"Alaska", @"Arizona", @"Arkansas", @"California", @"Colorado", @"Connecticut", @"Delaware", @"Florida", @"Georgia", @"Hawaii", @"Idaho", @"Illinois", @"Indiana", @"Iowa", @"Kansas", @"Kentucky", @"Louisiana", @"Maine", @"Maryland", @"Massachusetts", @"Michigan", @"Minnesota", @"Mississippi", @"Missouri", @"Montana", @"Nebraska", @"Nevada", @"New Hampshire", @"New Jersey", @"New Mexico", @"New York", @"North Carolina", @"North Dakota", @"Ohio", @"Oklahoma", @"Oregon", @"Pennsylvania", @"Rhode Island", @"South Carolina", @"South Dakota", @"Tennessee", @"Texas", @"Utah", @"Vermont", @"Virginia", @"Washington", @"West Virginia", @"Wisconsin", @"Wyoming", nil];
}


@end
