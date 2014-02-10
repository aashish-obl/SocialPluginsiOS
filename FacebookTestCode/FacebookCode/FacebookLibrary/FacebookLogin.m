//
//  FacebookLogin.m
//  FacebookLibrary
//
//  Created by Pushparaj Zala on 2/7/14.
//  Copyright (c) 2014 Pushparaj Zala. All rights reserved.
//

#import "FacebookLogin.h"

@implementation FacebookLogin


/* basic login method with default permission and nil complitionhandler */
+ (NSError *)login
{
    return [FacebookLogin login:@[@"basic_info"] withCompltion:nil];
}


/*login with default permission*/
//block-comlition handler block

+ (NSError *) loginWithFBCompletionHandler:(FBCompletionHandler) block
{
    return  [FacebookLogin login:@[@"basic_info"] withCompltion:block];

}

/*login with given read permission*/
//block-comlition handler block
//permission- read permissions

+ (NSError *) loginWithFBReadPermissions:(NSArray *)permission
           andCompletionHandler: (FBCompletionHandler) block
{
    return [FacebookLogin login:permission withCompltion:block];

}

/*private method for login with read permissions or login with basic info*/
+ (NSError *)login:(NSArray*)permission withCompltion:(FBCompletionHandler)block
{
    __block NSError *errorInside=nil;
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        NSLog(@"Found a cached session");
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:permission
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          if (error) {
                                              errorInside=error;
                                          }
                                          else
                                          {
                                          [FacebookLogin sessionStateChanged:session state:state error:error];
                                          block();
                                          }
                                      }];
        
        // If there's no cached session..
    }
    else
    {
        FBSession *session = [[FBSession alloc] initWithPermissions:permission];
        // Set the active session
        [FBSession setActiveSession:session];
        // Open the session
        
        [session openWithBehavior:FBSessionLoginBehaviorForcingWebView
                completionHandler:^(FBSession *session,
                                    FBSessionState state,
                                    NSError *error) {
                    //AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
                    if (error) {
                        errorInside=error;
                    }
                    else
                    {
                        [FacebookLogin sessionStateChanged:session state:state error:error];
                        block();
                    }
                }];
    }
    return errorInside;
}

/*login with given publish permission*/
//block-comlition handler block
//permission- publish permissions

+ (NSError *) loginWithFBPublishPermissions:(NSArray *)permission
                  andCompletionHandler: (FBCompletionHandler) block
{
    __block NSError *errorInside=nil;
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        NSLog(@"Found a cached session");
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithPublishPermissions:permission
                                           defaultAudience:FBSessionDefaultAudienceFriends
                                              allowLoginUI:NO
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             // Handler for session state changes
                                             // This method will be called EACH time the session state changes,
                                             [FacebookLogin sessionStateChanged:session state:state error:error];
                                             if (error) {
                                                 errorInside=error;
                                             }
                                             else
                                             {
                                                 [FacebookLogin sessionStateChanged:session state:state error:error];
                                                 block();
                                             }
                                         }];
        
        // If there's no cached session..
    }
    else
    {
        FBSession *session = [[FBSession alloc] initWithPermissions:permission];
        // Set the active session
        [FBSession setActiveSession:session];
        // Open the session
        
        [session openWithBehavior:FBSessionLoginBehaviorForcingWebView
                completionHandler:^(FBSession *session,
                                    FBSessionState state,
                                    NSError *error) {
                    //AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

                    if (error) {
                        errorInside=error;
                    }
                    else
                    {
                        [FacebookLogin sessionStateChanged:session state:state error:error];
                        block();
                    }
                }];
    }
    return errorInside;
}

#pragma mark - Logout
/*logout from facebook - current session*/

+ (BOOL) logout
{
    BOOL isLogout = NO;
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
    {
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        isLogout=YES;
        // If the session state is not any of the two "open" states when method is called
    }
    else
    {
        NSLog(@"Logged out can't be performed because you are not logged in state....!!");
    }
    return isLogout;
}


+ (BOOL)isLogin
{
    return (FBSession.activeSession.state == FBSessionStateOpen||FBSession.activeSession.state == FBSessionStateOpenTokenExtended);
}

//changes to be made when session state change or handle the errors...
+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        // Show the user the logged-in UI

        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
        // Show the user the logged-out UI

    }
    
    // Handle errors
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [self showMessage:alertText withTitle:alertTitle];
                
                // For simplicity, here we just show a generic message for all other errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI

    }

}



+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK!"
                      otherButtonTitles:nil] show];
}


@end
