# Conga Flow Redirect

A Lightning Web Component (LWC) designed for Salesforce Flows launched via actions that displays a message and automatically redirects users after the Flow closes.

## Overview

\cng_flowRedirect\ is a Flow screen component that provides a seamless user experience by:
- Displaying a customizable message with HTML support
- Showing an optional loading spinner
- Gracefully closing the Flow
- Redirecting to either a specific record or a custom URL

This component is ideal for creating exit screens in Flows that need to navigate users to a new location after Flow completion.

## Features

- **Flexible Redirect Targets**: Navigate to a Salesforce record or any custom URL
- **Rich Message Support**: Display messages with HTML formatting (bold, line breaks, links, etc.)
- **Loading Indicator**: Optional spinner to indicate the redirect is processing
- **Smart Timing**: 2-second message display followed by automatic redirect
- **Flow Integration**: Properly closes the Flow modal before redirecting

## Installation

1. Clone or download this repository
2. Deploy the component to your Salesforce org using Salesforce CLI:
   \\\Bash
   sf project deploy start --source-dir force-app/main/default/lwc/cng_flowRedirect
   \\\

## Usage

### Adding to a Flow

1. Open Flow Builder in Salesforce
2. Add a new Screen element
3. Click the Lightning component icon
4. Search for and select **cng_flowRedirect**
5. Configure the component properties (see Configuration section below)

### Basic Example

**Redirect to a Record:**
- Set \
recordId\ to the target record ID
- Optionally set a message like "Redirecting to your record..."

**Redirect to a URL:**
- Set \
redirectUrl\ to the target URL
- Optionally customize the \message\

## Configuration

The component accepts the following properties:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| \
recordId\ | String | No | The Salesforce Record ID to navigate to. When set, the user will be redirected to the record's lightning view. |
| \
redirectUrl\ | String | No | A relative or absolute URL to redirect to. Used if \
recordId\ is not provided. |
| \message\ | String | No | A message to display to the user before redirecting. Supports basic HTML tags (bold, line breaks, links). |
| \showSpinner\ | Boolean | No | Whether to display a loading spinner. Defaults to \	rue\. |

**Note:** At least one redirect target (\
recordId\ or \
redirectUrl\) should be provided, otherwise the component will log an error.

## Behavior

1. Component renders with optional spinner and message
2. After 2 seconds, the Flow is closed via \FlowNavigationFinishEvent\
3. After an additional 400ms delay, the redirect is performed
4. User is taken to the target location (record or URL)

### Redirect Priority

The component prioritizes redirect targets in this order:
1. \
recordId\ - If provided, navigates to this record
2. \
redirectUrl\ - If \
recordId\ is not set, navigates to this URL
3. Error - If neither is provided, an error is logged to the console

## Example Flow Configuration

**Scenario:** Show a confirmation message and redirect to an Account record

\\\
Flow Properties:
- recordId: {!AccountId}
- message: "Thank you! Redirecting to the account..."
- showSpinner: true
\\\

**Scenario:** Redirect to an external URL with a custom message

\\\
Flow Properties:
- redirectUrl: "https://example.com/success"
- message: <strong>Success!</strong><br/>You will be redirected shortly.
- showSpinner: true
\\\

## Technical Details

### Component Structure

- **cng_flowRedirect.js**: Main component logic
  - Handles redirect logic
  - Manages Flow navigation events
  - Controls timing delays

- **cng_flowRedirect.html**: Component template
  - Displays spinner and message
  - Uses Lightning Design System (SLDS) for styling

- **cng_flowRedirect.js-meta.xml**: Component metadata
  - Defines component as a Flow Screen target
  - Configures exposed properties

### Dependencies

- Lightning Navigation Mixin (\lightning/navigation\)
- Flow Support API (\lightning/flowSupport\)
- Lightning Design System (SLDS)

## Development

### Running Tests

\\\bash
npm test
\\\

### Project Structure

\\\
force-app/main/default/lwc/cng_flowRedirect/
 cng_flowRedirect.html          # Component template
 cng_flowRedirect.js            # Component logic
 cng_flowRedirect.js-meta.xml   # Component configuration
 __tests__/
     cng_flowRedirect.test.js   # Unit tests
\\\

## Browser Compatibility

This component works with all modern browsers supported by Salesforce Lightning.

## Troubleshooting

**Component not redirecting?**
- Ensure at least one redirect target (\
recordId\ or \
redirectUrl\) is provided
- Check browser console for error messages
- Verify the Record ID or URL is valid

**Message not displaying?**
- Ensure the \message\ property is set
- Check that HTML syntax is correct if using HTML formatting

**Spinner not showing?**
- Verify \showSpinner\ is not set to \alse\
- Ensure \message\ is provided (spinner displays above message)

## Support

For issues or questions, please contact the development team.
