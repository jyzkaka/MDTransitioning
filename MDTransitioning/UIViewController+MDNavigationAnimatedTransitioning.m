//
//  UIViewController+MDNavigationAnimatedTransitioning.m
//  MDTransitioning
//
//  Created by Jave on 2017/7/26.
//  Copyright © 2017年 markejave. All rights reserved.
//

#import <objc/runtime.h>
#import "UIViewController+MDNavigationAnimatedTransitioning.h"
#import "MDPopInteractionController.h"
#import "MDNavigationAnimationController.h"

@implementation UIViewController (MDNavigationAnimationController)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL origSel = @selector(viewWillDisappear:);
        SEL altSel = @selector(swizzle_viewWillDisappear:);
        Method origMethod = class_getInstanceMethod(class, origSel);
        Method altMethod = class_getInstanceMethod(class, altSel);
        IMP origIMP = class_getMethodImplementation(class, origSel);
        if (origIMP != NULL) {
            method_exchangeImplementations(origMethod, altMethod);
        }
        
        origSel = @selector(viewDidLoad);
        altSel = @selector(swizzle_viewDidLoad);
        origMethod = class_getInstanceMethod(class, origSel);
        altMethod = class_getInstanceMethod(class, altSel);
        origIMP = class_getMethodImplementation(class, origSel);
        if (origIMP != NULL) {
            method_exchangeImplementations(origMethod, altMethod);
        }
    });
}

- (void)swizzle_viewDidLoad{
    [self swizzle_viewDidLoad];
    
    if ([self allowPopInteractive] &&
        ![self allowCustomePopInteractive] &&
        [self navigationController] != nil &&
        [self navigationController] == [self parentViewController] &&
        [[[self navigationController] viewControllers] firstObject] != self) {
        
        self.interactiveController = [self requirePopInteractionController];
    }
}

- (void)swizzle_viewWillDisappear:(BOOL)animated {
    [self swizzle_viewWillDisappear:animated];
    // Being popped, take a snapshot
    if ([self isMovingFromParentViewController]) {
        self.snapshot = [[[self navigationController] view] snapshotViewAfterScreenUpdates:NO];
    }
}

- (UIView *)snapshot{
    return objc_getAssociatedObject(self, @selector(snapshot));
}

- (void)setSnapshot:(UIView *)snapshot{
    if ([self snapshot] != snapshot) {
        objc_setAssociatedObject(self, @selector(snapshot), snapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setAllowPopInteractive:(BOOL)allowPopInteractive{
    objc_setAssociatedObject(self, @selector(allowPopInteractive), @(allowPopInteractive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowPopInteractive{
    id allowPopInteractiveAssociatedObject = objc_getAssociatedObject(self, @selector(allowPopInteractive));
    if (!allowPopInteractiveAssociatedObject) {
        allowPopInteractiveAssociatedObject = @YES;
        self.allowPopInteractive = YES;
    }
    return [allowPopInteractiveAssociatedObject boolValue];
}

- (void)setAllowCustomePopInteractive:(BOOL)allowCustomePopInteractive{
    objc_setAssociatedObject(self, @selector(allowCustomePopInteractive), @(allowCustomePopInteractive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowCustomePopInteractive{
    return [objc_getAssociatedObject(self, @selector(allowCustomePopInteractive)) boolValue];
}

- (id<MDInteractionControllerDelegate>)interactiveController{
    return objc_getAssociatedObject(self, @selector(interactiveController));
}

- (void)setInteractiveController:(id<MDInteractionControllerDelegate>)interactiveController{
    if ([self interactiveController] != interactiveController) {
        objc_setAssociatedObject(self, @selector(interactiveController), interactiveController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (id<MDInteractionControllerDelegate>)requirePopInteractionController;{
    return [MDPopInteractionController interactionControllerWithViewController:self];
}

- (id<MDNavigationAnimatedTransitioning>)animationForNavigationOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;{
    if (operation == UINavigationControllerOperationPush) return nil;
    return [[MDNavigationAnimationController alloc] initWithOperation:operation fromViewController:fromViewController toViewController:toViewController];
}

@end