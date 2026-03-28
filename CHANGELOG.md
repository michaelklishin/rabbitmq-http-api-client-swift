# Change Log

## 0.8.0 (in development)

### Enhancements

 * `ExchangeType` now supports a `.plugin(String)` catch-all for arbitrary plugin exchange types

### Breaking Changes

 * Removed `ExchangeType.delayedMessage` (`x-delayed-message`): the x-delayed-exchange plugin
   has been discontinued

## 0.7.0 (Mar 15, 2026)

#### Initial Release

This library, heavily inspired by the [one available to Rust users](https://github.com/michaelklishin/rabbitmq-http-api-rs)
and powering `rabbitmqadmin` v2, is now mature enough to be publicly released.

It tries to port the Rust client API and feature set as faithfully as possible
in a different language with different idioms and approaches.

It targets Swift 6.x.
