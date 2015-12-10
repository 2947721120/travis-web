`import Ember from 'ember'`
`import { githubRepo } from 'travis/utils/urls'`
`import Config from 'travis/config/environment'`

Controller = Ember.Controller.extend
  jobController: Ember.inject.controller('job')
  buildController: Ember.inject.controller('build')
  reposController: Ember.inject.controller('repos')
  currentUserBinding: 'auth.currentUser'

  classNames: ['repo']

  build: Ember.computed.alias('buildController.build')
  job: Ember.computed.alias('jobController.job')

  slug: (-> @get('repo.slug') ).property('repo.slug')
  isLoading: (-> @get('repo.isLoading') ).property('repo.isLoading')

  init: ->
    @_super.apply this, arguments
    if !Ember.testing
      Visibility.every @config.intervals.updateTimes, @updateTimes.bind(this)

  updateTimes: ->
    Ember.run this, ->
      if builds = @get('builds')
        builds.forEach (b) -> b.updateTimes()

      if build = @get('build')
        build.updateTimes()

      if build && jobs = build.get('jobs')
        jobs.forEach (j) -> j.updateTimes()

  deactivate: ->
    @stopObservingLastBuild()

  activate: (action) ->
    @stopObservingLastBuild()
    this["view_#{action}".camelize()]()

  viewIndex: ->
    @observeLastBuild()
    @connectTab('current')

  viewCurrent: ->
    @observeLastBuild()
    @connectTab('current')

  viewBuilds: ->
    @connectTab('builds')

  viewPullRequests: ->
    @connectTab('pull_requests')

  viewBranches: ->
    @connectTab('branches')

  viewBuild: ->
    @connectTab('build')

  viewJob: ->
    @connectTab('job')

  viewRequests: ->
    @connectTab('requests')

  viewCaches: ->
    @connectTab('caches')

  viewRequest: ->
    @connectTab('request')

  viewSettings: ->
    @connectTab('settings')

  lastBuildDidChange: ->
    Ember.run.scheduleOnce('actions', this, @_lastBuildDidChange);

  lastBuildKey: ->
    key = if Config.useV3API
      'repo.defaultBranch.lastBuild'
    else
      'repo.lastBuild'

  _lastBuildDidChange: ->
    build = @get(@lastBuildKey())
    debugger
    @set('build', build)

  stopObservingLastBuild: ->
    @removeObserver(@lastBuildKey(), this, 'lastBuildDidChange')

  observeLastBuild: ->
    @lastBuildDidChange()
    @addObserver(@lastBuildKey(), this, 'lastBuildDidChange')

  connectTab: (tab) ->
    # TODO: such implementation seems weird now, because we render
    #       in the renderTemplate function in routes
    name = if tab == 'current' then 'build' else tab
    @set('tab', tab)

  urlGithub: (->
    githubRepo(@get('repo.slug'))
  ).property('repo.slug')

`export default Controller`
