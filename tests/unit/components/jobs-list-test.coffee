`import { test, moduleForComponent } from 'ember-qunit'`

moduleForComponent 'jobs-list', 'JobsListComponent', {
  needs: ['helper:format-duration', 'component:jobs-item']
}

test 'it renders a list of jobs', ->
  jobs = [Ember.Object.create(id: 1, state: 'passed'),
          Ember.Object.create(id: 1, state: 'failed')]

  component = @subject(jobs: jobs, required: true)
  @append()

  equal component.$('.section-title').text().trim(), 'Build Jobs'
  equal component.$('.jobs-item').length, 2, 'there should be 2 job items'
  ok component.$('.jobs-item:nth(0)').hasClass('passed'), 'passed class should be applied to a job'
  ok component.$('.jobs-item:nth(1)').hasClass('failed'), 'failed class should be applied to a job'

test 'it renders "Allowed Failures" version without a `required` property', ->
  jobs = [Ember.Object.create(id: 1)]

  component = @subject(jobs: jobs)
  @append()

  ok component.$('.section-title').text().match /Allowed Failures/
