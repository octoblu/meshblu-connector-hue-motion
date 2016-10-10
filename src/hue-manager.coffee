_              = require 'lodash'
HueUtil        = require 'hue-util'
{EventEmitter} = require 'events'
debug          = require('debug')('meshblu-connector-hue:hue-manager')

class HueManager extends EventEmitter
  connect: ({@ipAddress, @apiUsername, @sensorName, @pollBy, @sensorPollInterval, @apikey}, callback) =>
    @_emit = _.throttle @emit, 500, {leading: true, trailing: false}
    @apikey ?= {}
    {username} = @apikey
    @apiUsername ?= 'newdeveloper'
    @apikey.devicetype = @apiUsername
    @hue = new HueUtil @apiUsername, @ipAddress, username, @_onUsernameChange
    @_setInitialState (error) =>
      return callback error if error?
      @_createPollInterval()
      callback()

  close: (callback) =>
    clearInterval @pollInterval
    callback()

  _checkMotion: (callback) =>
    @hue.checkMotion (error, result) =>
      console.error error if error?
      return callback error if error?
      result = result.presence[@sensorName] if @pollBy
      result = result if !@pollBy
      callback null, result

  _createPollInterval: =>
    clearInterval @pollInterval
    @pollInterval = setInterval @_pollSensor, @sensorPollInterval if @sensorPollInterval?

  _onUsernameChange: (username) =>
    return if username == @apikey.username
    @apikey.username = username
    @_emit 'change:username', {@apikey}

  _pollSensor: (callback=->) =>
    @_checkMotion (error, result) =>
      return callback error if error?
      return callback() if _.isEqual result, @previousResult
      @previousResult = result
      result = { motion: result, name: @sensorName } if @pollBy
      @_emit 'motion', result

  _setInitialState: (callback) =>
    @_checkMotion (error, result) =>
      return callback error if error?
      @previousResult = result
      callback()

module.exports = HueManager
