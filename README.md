# NiceBiometrics

A SwiftUI library that simplifies the handling of various biometric states, controls, and error handling.

## TLDR
1. Enter NSFaceIDUsageDescription in Info.plist
2. Initialize NiceBiometrics with a config
```
@StateObject var niceBiometrics = NiceBiometrics(config: BiometricsConfig(
    keychainKey: "demo.nicebiometrics",
    policy: .deviceOwnerAuthenticationWithBiometrics,
    localizedReason: .standard,
    fallbackOption: .disabled,
    requiresAuthenticationToDisable: false
))
```
3. Make `NiceBiometrics` available to your views using `EnvironmentObject`
```
var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(niceBiometrics)
    }
}
```
4. For the settings toggle, use
```
BiometricsToggleSection()
```

5. For the authentication button, use
```
BiometricsButton {
    navigationManager.showSettings()
} passwordLogin: {
    navigationManager.showSettings()
}
```


## Introduction
Biometrics authentication is one of those things where the happy-path is easy to implement, but has subtle complexities in its configuration and in its error-handling. If the configuration and error-handling are not properly implemented, it could break the app entirely as users might be prevented from signing in. Getting all of it right can actually be quite time-consuming and tricky, so the goal of NiceBiometrics is to do all of those tedious work for you in-advance, so that you can focus on writing more interesting and mission-critical code. While this library is still early in its development, it already has a "drag and drop then forget" kind of simplicity and elegance to it, and I look forward to completing it over the next few months. For now, I'd love to show you how it currently works.

## The Problems
First, I want to cover some interesting problems that I don't think many are aware of beacuse critical details are somewhat buried in the documentation, biometrics authentication is not something we work with daily (often only once per app), and most of the time it seems to work fine (making you think the job is done). So, in my opinion it is kind of hard to get right, and it's really nice to have NiceBiometrics covering our backs.

The problems are:
1. Subtle Flow Differences
2. Error Handling
3. App Lifecycle

### 1. Subtle Flow Differences
There are two main [LAPolicy](https://developer.apple.com/documentation/localauthentication/lapolicy) to initiate biometrics authentication with, and their resulting flows are subtly different from one another. Therefore, it is important to be aware of that, and to decide early in design on which one to use, because the LAPolicy you choose will affect the authentication UI and flow in your app:

#### LAPolicy.deviceOwnerAuthenticationWithBiometrics

##### Prompt Requirements
When using [deviceOwnerAuthenticationWithBiometrics](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithbiometrics), biometrics authentication is not possible if:
- a device passcode is not set
- biometry is not available, not enrolled, or locked out

The key here is that no authentication prompt will be shown if one of the reasons above is true, and you have to implement some error-handling UI on your own, otherwise it's hard to know why the app isn't responding. Luckily, NiceBiometrics does this for us.

##### Prompt Differences
The prompt also looks and behaves slightly differently between Touch ID and Face ID devices:
- On Touch ID devices:
  - When the prompt is displayed, it needs to wait for your input, so the cancel button is also available right away
  - There is no "Try Again" button, as re-placing one's finger on the Home button serves the same function
- On Face ID devices:
  - When the prompt is displayed, the device immediately starts scanning, so the cancel button only shows up if the initial scan fails
  - There is a "Try Again" button, because if the device doesn't wait for the user after the first failed attempt, it could result in multiple scan failures in quick succession and cause a lockout

|Face ID Prompt|Face ID Try Again|Touch ID Prompt|Touch ID Try Again|
|----|----|----|----|
|![prompt-1](https://github.com/steamclock/niceBiometrics/assets/4675020/cbfa5dfe-2e10-478e-9edb-d6d3c43e65f0)|![prompt-2](https://github.com/steamclock/niceBiometrics/assets/4675020/2cfbc9f9-6b81-46f5-b5d5-c9441ceec38a)|![prompt-3](https://github.com/steamclock/niceBiometrics/assets/4675020/88664192-f255-4f40-9528-5934596d1164)|![prompt-4](https://github.com/steamclock/niceBiometrics/assets/4675020/00715a0f-9edc-4c7f-a8ad-58f77bfb5a00)|

##### Fallback Button
And for both Touch ID and Face ID devices, the default fallback button is "Enter Password" when using deviceOwnerAuthenticationWithBiometrics. The fallback option is displayed after the 1st failed attempt on a Touch ID device, but on a Face ID device it is only displayed after the 2nd failed attempt. This is not the same as the device passcode. It is an arbitrary password you can use to determine whether the app should allow the user to still proceed if they know the right password. For most cases, the fallback button isn't very useful, because it kind of defeats the purpose of having biometrics authentication, and it also requires extra view and logic setup. Most apps seem to just disable it, and the way to disable it is a little hidden as well 😅

```
let context = LAContext()
// explicitly specify an empty string to disable the fallback button
context.localizedFallbackTitle = ""
```

#### LAPolicy.deviceOwnerAuthentication
When using [deviceOwnerAuthentication](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication), most of the behaviours are the same with the following exceptions:

1. if biometrics authentication is unavailable, <em>a passcode prompt will show</em>
2. if biometrics authentication is available, but there is a failed attempt, the default fallback button is "Enter Passcode" instead of "Enter Password"

And since passcode authentication is now involved, it is worth knowing that like the protection on a lockscreen, 6 failed passcode attempts will completely disable the device. Because of this very reason, this is most likely not the right LAPolicy for most consumer, productivity, and entertainment apps. Apps that deal with extremely sensitive data, such as medical or corporate apps could use this.

|Password Fallback|Passcode Fallback|Passcode Screen|
|----|----|----|
|![fallback-1](https://github.com/steamclock/niceBiometrics/assets/4675020/1039714b-0633-4785-aaf7-3dc1d2406013)|![fallback-2](https://github.com/steamclock/niceBiometrics/assets/4675020/de8d9a99-d4ea-4292-b362-21bbbbe5fe59)|![fallback-3](https://github.com/steamclock/niceBiometrics/assets/4675020/f87502e6-7ccf-47dd-85d8-d1d48f40ccab)|

#### Other LAPolicy and Best Practices
There are also other [LAPolicy](https://developer.apple.com/documentation/localauthentication/lapolicy) available, but they are for supporting Apple Watch, and that's a discussion for another day. In short, most apps probably want to use the <b>WithBiometrics</b> policy. Contrary, use <b>deviceOwnerAuthentication</b> if you are sure your app needs to leverage passcode authentication. I recommend disabling the fallback button as well when using <b>WithBiometrics</b>, unless you've identified a specific reason for allowing the circumvention of biometrics authentication. On the other hand, you probably <b>don't</b> want to disable the fallback button when you are using <b>deviceOwnerAuthentication</b>, because that will disable passcode authentication altogether, which probably goes against the very reason why you chose that LAPolicy in the first place.

### 2. Error Handling
There are a few [errors](https://developer.apple.com/documentation/localauthentication/laerror/) related to biometrics authentication that can be confusing and unclear, so I want to help clarify those specific ones:

| Error                | Triggering Conditions                                                                                                                                                                                                                   | Required User Action                                                                                          |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| passcodeNotSet       | This means the device doesn't have a passcode set, so neither biometric nor passcode authentication is available.                                                                                                                       | The user must go to the system settings and create a passcode.                                                |
| biometryNotEnrolled  | This means there are no registered fingerprints on a Touch ID device, or no scanned face on a Face ID device.                                                                                                                           | The user must go to the system settings and enable a biometry.                                                |
| biometryNotAvailable | This is the most confusing one because it has two causes: permission for app to use biometric authentication is rejected by the user on first request, or the user has disabled it manually from app preferences under system settings. | The user must go to the app's preferences under system settings and re-toggle biometric authentication there. |

|Not Enrolled Error|Not Available Error|Passcode Required Error|Lockout Error|
|----|----|----|----|
|![error-1](https://github.com/steamclock/niceBiometrics/assets/4675020/bd4d808b-d349-4f81-8abb-bbbd7e989624)|![error-2](https://github.com/steamclock/niceBiometrics/assets/4675020/502a3098-a132-4120-879d-62aced4b7209)|![error-3](https://github.com/steamclock/niceBiometrics/assets/4675020/9648d866-d858-442d-8bbf-7bfbc657ce27)|![error-4](https://github.com/steamclock/niceBiometrics/assets/4675020/635fc891-076f-4ef9-b744-1789da0c3de7)|

There is also an error called biometryLockout that is quite interesting. If the user has "Face ID with a Mask" turned on, then <b>regardless</b> of how many failed attempts there are, this error <b>will never</b> trigger.

|Face ID Mask Setting|
|----|
|![mask-setting](https://github.com/steamclock/niceBiometrics/assets/4675020/6572a2db-1c6d-442e-94b8-b7ecdb00679b)|

As you can see, error-handling requires a bit of finesse and attention to details, especially if you are starting from scratch. However, NiceBiometrics takes care of all of this for us.

### 3. App Lifecycle

Following up the topic on error-handling, the user needs to background the app in order to navigate to system settings, and is subsequently expected to return to the app after fixing a few things. Some actions such as switching the biometry toggle in app preferences will terminate the app, others like remedying a biometry lockout won't. So regardless, we must update the UI on resuming the app. Although this might seem obvious at first, it is surprisingly common for this step to be forgotten. Everything we've discussed up to this point, such as the happy-path being easy to implement, the policies being subtly different, and the errors misunderstood or underestimated, are reasons for this final piece to be left out accidentally.

NiceBiometrics has also got you covered here, so that when users have done all the hard work to fix an issue, they don't come back to an app that still appears broken. We're finally ready to take a look at how to integrate NiceBiometrics into your app.

## The Solutions
NiceBiometrics helps solve all of the mentioned problems above via two mechanisms:
1. A config that makes sure you don't forget any important decision
2. Pre-built SwiftUI views with error-handling and view lifecycle awareness

### The Config
In order to initialize NiceBiometrics, you must pass in the following configuration, which also serves as a questionnaire of sort to help you guarantee that all the necessary details are provided up-front, including <b>localizedReason</b>:

```
BiometricsConfig(
    keychainKey: "demo.nicebiometrics",
    policy: .deviceOwnerAuthenticationWithBiometrics,
    localizedReason: .standard,
    fallbackOption: .disabled,
    requiresAuthenticationToDisable: false
)
```

### The Button
A sign in button that can update itself accordingly based on the latest states of biometric authentication. To use it, just insert the following code in your view:

```
BiometricsButton {
    navigationManager.showSettings()
} passwordLogin: {
    navigationManager.showSettings()
}
.environmentObject(niceBiometrics) // if not already injected from a container view
```

|Sign in with Biometry|Sign in without Biometry|
|----|----|
|![button-enabled](https://github.com/steamclock/niceBiometrics/assets/4675020/e99d4e7d-250c-4d48-aa6a-8e643af210c8)|![button-disabled](https://github.com/steamclock/niceBiometrics/assets/4675020/cb70c4bc-f9ed-4adf-9dc4-4f2ebbb31def)|

### The Toggle
An elegant toggle with comprehensive error-handling that really helps the users when there's an error. To use it, just insert the following code in a List (most likely your in-app settings screen):

```
BiometricsToggleSection()
    .environmentObject(niceBiometrics) // if not already injected from a container view
```
|Biometry Toggle Section|
|----|
|![toggle-section](https://github.com/steamclock/niceBiometrics/assets/4675020/9b54e5e4-bdc3-4285-9049-62740645175e)|

## Next Steps
As mentioned before, this is still a very early version and much work still remains. For examples:

- Add Apple Watch support
- More view customization options
- More fallback button support

I hope this library can help us save a lot of time the next time an app needs to support biometric authentication!
