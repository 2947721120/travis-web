`import ExpandableRecordArray from 'travis/utils/expandable-record-array'`
`import Model from 'travis/models/model'`
# TODO: Investigate for some weird reason if I use durationFrom here not durationFromHelper,
#       the function stops being visible inside computed properties.
`import { durationFrom as durationFromHelper } from 'travis/utils/helpers'`
`import Build from 'travis/models/build'`

Repo = Model.extend
  ajax: Ember.inject.service()

  slug:                DS.attr()
  description:         DS.attr()
  private:             DS.attr('boolean')
  githubLanguage:      DS.attr()
  active:              DS.attr()

  #lastBuild:     DS.belongsTo('build')
  defaultBranch: DS.belongsTo('branch', async: false)

  # just for sorting
  lastBuildFinishedAt: Ember.computed.oneWay('defaultBranch.lastBuild.finishedAt')
  lastBuildId: Ember.computed.oneWay('defaultBranch.lastBuild.id')

  withLastBuild: ->
    @filter( (repo) -> repo.get('defaultBranch.lastBuild') )

  sshKey: (->
    @store.find('ssh_key', @get('id'))
    @store.recordForId('ssh_key', @get('id'))
  )

  envVars: (->
    id = @get('id')
    @store.filter('env_var', { repository_id: id }, (v) ->
      v.get('repo.id') == id
    )
  ).property()

  builds: (->
    id = @get('id')
    builds = @store.filter('build', event_type: ['push', 'api'], repository_id: id, (b) ->
      b.get('repositoryId')+'' == id+'' && (b.get('eventType') == 'push' || b.get('eventType') == 'api')
    )

    # TODO: move to controller
    array  = ExpandableRecordArray.create
      type: 'build'
      content: Ember.A([])

    array.load(builds)
    array.observe(builds)

    array
  ).property()

  pullRequests: (->
    id = @get('id')
    builds = @store.filter('build', event_type: 'pull_request', repository_id: id, (b) ->
      b.get('repositoryId')+'' == id+'' && b.get('eventType') == 'pull_request'
    )

    # TODO: move to controller
    array  = ExpandableRecordArray.create
      type: 'build'
      content: Ember.A([])

    array.load(builds)

    id = @get('id')
    array.observe(builds)

    array
  ).property()

  branches: (->
    builds = @store.query 'build', repository_id: @get('id'), branches: true

    builds.then ->
      builds.set 'isLoaded', true

    builds
  ).property()

  owner: (->
    (@get('slug') || '').split('/')[0]
  ).property('slug')

  name: (->
    (@get('slug') || '').split('/')[1]
  ).property('slug')

  sortOrderForLandingPage: (->
    state = @get('defaultBranch.lastBuild.state')
    if state != 'passed' && state != 'failed'
      0
    else
      parseInt(@get('defaultBranch.lastBuild.id'))
  ).property('defaultBranch.lastBuild.id', 'defaultBranch.lastBuild.state')

  stats: (->
    if @get('slug')
      @get('_stats') || $.get("https://api.github.com/repos/#{@get('slug')}", (data) =>
        @set('_stats', data)
        @notifyPropertyChange 'stats'
      ) && {}
  ).property('slug')

  updateTimes: ->
    if lastBuild = @get('defaultBranch.lastBuild')
      lastBuild.updateTimes()

  regenerateKey: (options) ->
    @get('ajax').ajax '/repos/' + @get('id') + '/key', 'post', options

  fetchSettings: ->
    @get('ajax').ajax('/repos/' + @get('id') + '/settings', 'get', forceAuth: true).then (data) ->
      data['settings']

  saveSettings: (settings) ->
    @get('ajax').ajax('/repos/' + @get('id') + '/settings', 'patch', data: { settings: settings })

Repo.reopenClass
  recent: ->
    @find()

  accessibleBy: (store, reposIds) ->
    # this fires only for authenticated users and with API v3 that means getting
    # only repos of currently logged in owner, but in the future it would be
    # nice to not use that as it may change in the future
    repos = store.filter('repo', (repo) ->
      reposIds.indexOf(parseInt(repo.get('id'))) != -1
    )

    promise = new Ember.RSVP.Promise (resolve, reject) ->
      store.query('repo', { 'repository.active': 'true', limit: 20 }).then( ->
        resolve(repos)
      , ->
        reject()
      )

    promise

  search: (store, ajax, query) ->
    queryString = $.param(search: query, orderBy: 'name', limit: 5)
    promise = ajax.ajax("/repos?#{queryString}", 'get')
    result = Ember.ArrayProxy.create(content: [])

    promise.then (data, status, xhr) ->
      promises = data.repos.map (repoData) ->
        store.findRecord('repo', repoData.id).then (record) ->
          result.pushObject(record)
          result.set('isLoaded', true)
          record

      Ember.RSVP.allSettled(promises).then ->
        result

  withLastBuild: (store) ->
    repos = store.filter('repo', {}, (build) ->
      build.get('defaultBranch.lastBuild')
    )

    repos.then () ->
      repos.set('isLoaded', true)

    repos

  fetchBySlug: (store, slug) ->
    repos = store.peekAll('repo').filterBy('slug', slug)
    if repos.get('length') > 0
      repos.get('firstObject')
    else
      adapter = store.adapterFor('repo')
      modelClass = store.modelFor('repo')
      adapter.findRecord(store, modelClass, slug).then (payload) ->
        serializer = store.serializerFor('repo')
        modelClass = store.modelFor('repo')
        result = serializer.normalizeResponse(store, modelClass, payload, null, 'findRecord')

        repo = store.push(data: result.data)
        for record in result.included
          r = store.push(data: record)

        repo
      , ->
        error = new Error('repo not found')
        error.slug = slug
        Ember.get(repos, 'firstObject') || throw(error)

  # buildURL: (slug) ->
  #   if slug then slug else 'repos'

`export default Repo`
