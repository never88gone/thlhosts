//
//  SceneDelegate.m
//  Browser
//
//  Created by copilot on 2025/11/11.
//

#import "SceneDelegate.h"
#import <UIKit/UIKit.h>
#import "HSBSmbApp-Swift.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  if (![scene isKindOfClass:[UIWindowScene class]])
    return;

  UIWindowScene *windowScene = (UIWindowScene *)scene;

  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
  self.window.backgroundColor = [UIColor systemBackgroundColor];
  
  // Initialize Swift ViewController via Factory
  UIViewController *rootVC = [HostsViewController makeRootViewController];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
  self.window.rootViewController = nav;
  [self.window makeKeyAndVisible];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
  // Restart any tasks that were paused.
}

- (void)sceneWillResignActive:(UIScene *)scene {
  // Sent when the scene will move from an active state to an inactive state.
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
  // Called as the scene transitions from background to foreground.
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
  // Called as the scene transitions from foreground to background.
}

@end
