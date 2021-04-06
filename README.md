# What the hell is that actor's name???

This repo is my own continuation of our group's work on our final project at the [Le Wagon Web Development coding bootcamp](https://www.lewagon.com/berlin/web-development-course/full-time). The project as we left it at the end of the bootcamp is deployed [here on Heroku](https://wth-actor-name.herokuapp.com/), and the repository is [here](https://github.com/MargauxPalvini/what-the-hell/tree/v1.0). Please do check out our original project and codebase!

This was an interesting and fun project to work on, especially as it tied together all the things we learned during the bootcamp and was for all of us in the group our first experience of collaborating on code with others. We had only two weeks to develop a working product from scratch at the end of an intense 9 week programme, and due to these time constraints we did not always have time to reach a consensus on important questions about the app's architecture and design.

Because of our disagreements about these structural decisions, I have decided to fork the project to be able to play with what I think might be a leaner, more efficient way to answer that ever-returning question: _what the hell is that actor's name???_

## Changes to be implemented

Some of the many changes I am aiming to make include:

### Removing all `ActiveRecord` models and database calls

In the context of this application there's no real need for searches to be recorded. In a future version there might be a need to record successful searches which led to the wanted result, but the current implementation is unnecessary and wasteful. We were asked to use a database purely as a learning opportunity, but our application could be cleaner and more efficient without one.

### Replacing the current `SearchesController`

Currently, the `SearchesController` uses `sidekiq` background jobs and Rails `WebSocket & Actioncable` to fetch results from various APIs and conditionally render the `searches/home` view based on the results of any search. The controller renders a minimal view, which is then updated dynamically through `WebSocket` as and when results become available. I added this implementation to our project, which made our application dramatically faster: this way, pageloads generally take ~50-150ms compared to previously, where sequential API calls meant that some searches took several seconds (even up to 10s...) to render a page. This also means that pages don't randomly crash when a response takes too long.

However, this implementation produced an unexpected problem in production: the background jobs containing the API calls would sometimes finish faster than the view would be rendered, which meant that the results would be broadcast through `ActionCable` before the correct subscriptions could be set up on the client. For our demo day, we 'solved' this problem by simply adding a 500ms sleep to each background job - however, I think a better solution would be to make use of threads instead of background jobs, and scrap `ActionCable` which isn't really the right tool for this anyway.

### Creating a proper desktop view

Due to our time constraints, we designed the app with one resolution (one specific phone, in fact) in mind - but not everyone will be using our app using that specific phone.

### Refactoring all of our JS

I would like to refactor all of the JavaScript plugins we created to use `Stimulus`, and perhaps make some improvements as well.

### Refactoring our backend

Apart from the fundamental backend changes outlined above, I'd like to reorganise and refactor our API calls, move logic into helper modules, and generally try to clean up our codebase a little.

### Writing tests

Learning how to write tests was not part of the bootcamp syllabus, and during the project weeks we definitely did not feel that we had time to learn, so now I would like to learn how to do proper testing in Rails to make the project more robust.
