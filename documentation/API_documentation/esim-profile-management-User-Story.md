# eSIM Profile Management API — User Stories

These user stories describe, at a business level, how an API Consumer uses the
eSIM Profile Management API to manage connectivity on devices with eSIM
hardware (eUICC). They are intended to convey intended use, not to document
individual endpoints — see the API definition for operation-level detail.

## Common pre-conditions

The following apply to all stories below and are not repeated in each:

1. The API Consumer has successfully onboarded with the API Provider and is
   eligible to use the eSIM Profile Management API.
2. The API Consumer has obtained an access token with the scopes required for
   the operations it invokes; the applicable authorization flows are agreed
   during onboarding.
3. The target device contains eSIM hardware (eUICC) capable of remote profile
   management, identified by its EID.
4. Operations that act on the device are asynchronous: the API accepts the
   request and returns an operation reference, and the outcome is retrieved by
   polling the operation.

## Story 1 — Provision and manage connectivity on a device

| **Item** | **Details** |
| ---- | ------- |
| ***Summary*** | As an API Consumer, I want to remotely install an eSIM Profile onto a device and manage its lifecycle, so that I can provide and control cellular connectivity without handling a physical SIM. |
| ***Roles, Actors and Scope*** | **Role:** API Consumer.<br>**Actors:** application and service providers managing connected devices on behalf of device owners.<br>**Scope:** install (download), activate (enable), deactivate (disable), and remove (delete) an eSIM Profile, and check profile status. |
| ***Story-specific pre-conditions*** | The API Consumer has a valid activation code for the eSIM Profile to be installed. |
| ***Activities/Steps*** | **Starts when:** the API Consumer requests download of an eSIM Profile to a device, providing the device EID and the activation code. The profile is installed in a disabled state and identified by an ICCID.<br>**Continues with:** enabling the profile to provide connectivity (only one profile is active per device at a time), and later disabling, re-enabling, or deleting it as needs change. Profile status can be checked at any point.<br>**Ends when:** the eSIM Profile is deleted from the device, or the API Consumer no longer needs to manage it. |
| ***Post-conditions*** | The device carries the eSIM Profile in the intended state (installed, active, inactive, or removed), and the API Consumer has confirmation of each requested change. |
| ***Exceptions*** | - Unauthorized: invalid or expired credentials.<br>- Invalid input: a required identifier is missing or malformed.<br>- Unknown identifier: the referenced device or profile does not exist.<br>- Conflict: the requested change is not valid for the profile's current state (e.g. enabling a profile while another is active).<br>- Not applicable: the operation cannot be applied to the referenced profile or device.<br>- Failed execution: the device could not be reached or the operation did not complete on the device. |

## Story 2 — Maintain connectivity resilience

| **Item** | **Details** |
| ---- | ------- |
| ***Summary*** | As an API Consumer, I want to designate a fallback eSIM Profile on a device, so that the device can recover connectivity automatically if its active profile becomes unusable. |
| ***Roles, Actors and Scope*** | **Role:** API Consumer.<br>**Actors:** providers managing devices that must stay connected.<br>**Scope:** configure a previously installed eSIM Profile as the fallback for a device. |
| ***Story-specific pre-conditions*** | At least one eSIM Profile is already installed on the target device to serve as the fallback. |
| ***Activities/Steps*** | **Starts when:** the API Consumer requests that a specified eSIM Profile be set as the device's fallback.<br>**Ends when:** the fallback configuration is confirmed for the device. |
| ***Post-conditions*** | The device has a designated fallback eSIM Profile and can restore connectivity to it automatically. |
| ***Exceptions*** | - Unauthorized: invalid or expired credentials.<br>- Unknown identifier: the referenced device or profile does not exist.<br>- Not applicable: the referenced profile cannot serve as a fallback for the device. |
