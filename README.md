# rammus

[![Build Status](https://travis-ci.org/eric-pigeon/rammus.svg?branch=master)](https://travis-ci.org/eric-pigeon/rammus) [![Coverage Status](https://coveralls.io/repos/github/eric-pigeon/rammus/badge.svg?branch=master)](https://coveralls.io/github/eric-pigeon/rammus?branch=master)

> Rammus is a Ruby library which provides a high-level API to control Chrome or Chromium over the [DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/). Rammus runs [headless](https://developers.google.com/web/updates/2017/04/headless-chrome) by default, but can be configured to run full (non-headless) Chrome or Chromium.

### Usage

```ruby
require 'rammus'

browser = Rammus.launch
page = browser.new_page
page.goto('https://example.com').await
page.screenshot path: 'example.png'

browser.close
```
