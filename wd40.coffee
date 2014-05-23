wd = require 'wd'

doInit = (cb) ->
  browser.init
    browserName: process.env.BROWSER ? 'chrome'
    'chrome.switches': ['--disable-extensions']
  , (err) ->
    if err
      console.warn "#{err.code}: Is your Selenium server running?"
    cb err

class wd40
  @init: (cb) ->
    browser.sessions (err, sessions) ->
      if sessions.length == 0
        doInit cb
        return

      console.log "wd40: Attaching to existing browser session"
      browser.attach sessions[0].id, (err) ->
        if err
          console.warn "wd40: Couldn't attach to existing session, try restarting selenium"
          return cb err
        browser.windowName (err) ->
          if err
            console.warn "wd40: Couldn't attach to existing session, reinitializing"
            browser.quit ->
              doInit cb
            return
          cb err

  @trueURL: (cb) ->
    browser.eval "window.location.href", cb

  @fill: (selector, text, cb) ->
    browser.waitForElementByCss selector, 4000, ->
      browser.elementByCss selector, (err, element) ->
        if err
          return cb err, null
        element.clear (err) ->
          browser.type element, text, cb

  @clear: (selector, cb) ->
    browser.waitForElementByCss selector, 4000, ->
      browser.elementByCss selector, (err, element) ->
        browser.clear element, cb

  @click: (selector, cb) ->
    wd40.waitForVisibleByCss selector, ->
      browser.elementByCss selector, (err, element) ->
        element.click cb

  @getText: (selector, cb) ->
    browser.waitForElementByCss selector, 4000, ->
      browser.elementByCss selector, (err, element) ->
        element.text cb

  # We always switch to the first frame here!
  @switchToFrame: (selector, cb) ->
    browser.waitForElementByCss selector, 4000, ->
      browser.frame 0, cb

  @switchToTopFrame: (cb) ->
    browser.windowHandle (err, handle) ->
      browser.window handle, cb

  @switchToBottomFrame: (cb) ->
    @switchToFrame 'iframe', =>
      @switchToFrame 'iframe', cb

  @waitForText: (text, arg1, arg2) ->
    if typeof(arg1) is 'number' and typeof(arg2) is 'function'
      cb = arg2
      timeout = arg1
    else if typeof(arg1) is 'function'
      cb = arg1
      timeout = 4000
    else
      return new Error("Invalid arguments supplied to waitForText()")
    endTime = Date.now() + timeout
    poll = ->
      browser.text 'body', (err, result) ->
        if err
          return cb err
        if result.indexOf(text) > -1
          cb null
        else
          if Date.now() > endTime
            cb new Error("Text didn't appear")
          else
            setTimeout poll, 200
    poll()

  @waitForMatchingURL: (regExp, cb) ->
    endTime = Date.now() + 4000
    poll = =>
      @trueURL (err, url) ->
        if err
          return cb err
        if regExp.test url
          cb null, url
        else
          if Date.now() > endTime
            cb new Error("No matching URL found")
          else
            setTimeout poll, 200
    poll()

  @elementByPartialLinkText: (text, callback) ->
    browser.waitForElementByPartialLinkText text, 4000, (err) ->
      callback(err) if err?
      browser.elementByPartialLinkText text, callback

  @elementByCss: (selector, callback) ->
    browser.waitForElementByCss selector, 4000, (err) ->
      callback(err) if err?
      browser.elementByCss selector, callback

  @waitForInvisible: (element, callback) ->
    endTime = Date.now() + 4000
    poll = ->
      browser.isVisible element, (err, visible) ->
        if err
          callback err
        else if not visible
          callback null
        else
          if Date.now() > endTime
            callback new Error("Element did not disappear")
          else
            setTimeout poll, 200
    poll()

  @waitForVisible: (element, callback) ->
    endTime = Date.now() + 4000
    poll = ->
      browser.isVisible element, (err, visible) ->
        if err
          callback err
        else if visible
          callback null
        else
          if Date.now() > endTime
            callback new Error("Element did not disappear")
          else
            setTimeout poll, 200
    poll()

  @waitForInvisibleByCss: (selector, callback) ->
    endTime = Date.now() + 4000
    poll = ->
      browser.isVisible 'css selector', selector, (err, visible) ->
        if err
          callback err
        else if not visible
          callback null
        else
          if Date.now() > endTime
            callback new Error("Element did not disappear")
          else
            setTimeout poll, 200
    poll()

  @waitForVisibleByCss: (selector, callback) ->
    endTime = Date.now() + 4000
    poll = ->
      browser.isVisible 'css selector', selector, (err, visible) ->
        if err
          callback err
        else if visible
          callback null
        else
          if Date.now() > endTime
            callback new Error("Element did not disappear")
          else
            setTimeout poll, 200
    poll()


# wd.remote works fine without defining a host and port
# but you can override them with these environment variables
seleniumHost = process.env.SELENIUM_HOST
seleniumPort = process.env.SELENIUM_PORT
exports.browser = browser = wd.remote seleniumHost, seleniumPort
exports.wd40 = wd40
