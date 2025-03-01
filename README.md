This readme is also available in [Russian](https://github.com/fedorkk/test_hotwire_app/blob/main/README_RU.md)
# Startup
To play with the code you need:
- ruby 3.3.5
- rails 8.0.1
- sqlite

To start the app:
- `git pull`
- `bundle install`
- `bundle exec rails db:create db:migrate db:seed`
- `bundle exec rails s`

You can open the site on [http://127.0.0.1:3000](http://127.0.0.1:3000)

# Test hotwire app

In this article I want to tell you about my experiments with Hotwire - a new technology for writing dynamic one-page applications without using complex frontend frameworks. The basic idea behind Hotwire is that when some action is taken on a page, a request is sent to the server, where a new piece of html document is rendered, which is sent back and replaces or supplements the existing page.

The technology consists of several components:
- Turbo:
    - Turbo Drive is responsible for replacing parts of the HTML on the page and prevents the page from completely reloading when a request is sent. This is actually the engine on which the entire technology runs
    - Turbo Frames allows you to divide pages into separate parts that can be modified separately from the entire page.
    - Turbo Streams add flexibility in handling server responses. With them, you can not only replace a single frame or an entire page, but also perform many different operations on a single request.
    - Turbo Native will be used in the future to create mobile applications, but is still in development.
- Stimulus is a JS library that replaces parts of html documents and makes requests to the server.

## Simplest example - reloading the whole page
I will use bootstrap to add styles to the page. To do this, I will create an application with the `--css=bootstrap` directive.
First, lets add a navigation bar to our `app/views/layouts/application.html.erb` layout. As well as the first route and controller for static pages `app/controllers/pages_controller.rb`.

Let's launch our application and see what happens when we click on the links in the navigation bar. If you open the developer panel in a browser and look at the network requests, you can see that the page is not reloaded completely. Instead, TurboJS makes a request to the server, loads only the html inside the `<body></body>` tags and replaces it. The css styles, JS scripts as well as the entire layout are not changed. In fact TurboDrive works in rails 7/8 automatically and you may not even notice it.

## A bit more interesting - TurboFrames
Let's open the second link in the navigation pannel. If you look at the code of this page you can see that the paragraph of the article is now surrounded by the `turbo_frame_tag` tags with the identifier `current_paragraph`. This is the same `turbo_frame` that we will be changing, and the frame changes another frame, so the new template that the controller returns must also have a `turbo_frame` with the same identifier. To do this, we will use partial templates that we render on the first call and return on the request. We need another endpoint in the controller: `turbo_frame_change` to which we will send the identifier of the desired paragraph, and which will return the corresponding frame. Open the developer panel in your browser again and make sure that the part of the page that is not surrounded by `turbo_frame` tags does not change and is not returned when you click on the link. To make the TurboDrive understands which frame we want to change, we need to tell it by adding the `data-turbo-frame` parameter to the link. Rails will do the rest for us with its famous magic!

Turbo frames allow us to dynamically change parts of the page, but their scope is quite small. We can only change one frame by requesting the same frame with different content. We don't have the ability to change multiple frames, or add something to the beginning or end. Only to change part of the html page as a whole.

## More flexibility - Turbo streams
TurboStream is a special request format that allows you to return a special turbo_stream view that describs the changes that need to be made to the page. TurboStream can work as a normal http request, and through web socket, changing the content on the client page when some event occurs on the server.

Let's create a new controller `TurboStreamsController` its functionality will be very similar to the previous one, so it will be easier to separate the contexts. Here we need two endpoints `init`, which we will open first by the link in the navigation menu and `call`, which will process `turbo_stream` requests. Pay attention to the format of the http request, now it is a `turbo_stream` and accordingly this format should be used when calling it. To do this we need to add the parameter `data: {turbo_stream: true}` to the links we are using. You can then see that we are initializing variables that will then be used in the `turbo_stream` template. This gives us quite a lot of scope for adding different logic to the page.

We can return the template directly from the controller if it is small (`render turbo_stream: turbo_stream.action ...`), or use a separate file. According to the standard naming, our template has the same name as the controller method and the extension `turbo_stream.erb`. Let's open the file and see what's in it. We are processing two actions:
1. Change the content of the html elements with id `paragrap_#{@old_paragraph}` to the content of the partial template. Note that we don't even need turbo_frames anymore. We can work with any html elements that can be identified by id or class.
2. We add an entry after the div with `id=“logs”`.

Thus, with `turbo_streams` we can perform several actions in one request and dynamically change different elements of the page. And not only replace the whole page, but also delete, add something to the beginning or end, etc.

## Stimulus, and a painful real life example
So far, we have been working with Turbo quite easily because we have been using links and sending requests to the server without any problems. However, in real life we have many user actions that need to be dynamically handled by the client, but are not link clicks and do not send a request automatically. To solve this problem, Rails offers Stimulus controllers. Stimulus is a JavaScript library that allows you to call functions specified in the `data-action` html parameter. Let's see how this works using the example of creating a dynamic form for an address. We will add some `select` fields, when the user selects a country we will load a list of cities for that country, and when the user selects a city we will load a list of streets for the city.

First, let's create the corresponding models: `Counrty`, `City`, `Street` and `Address`. Let's fill them with simple seeds (`db/seeds.rb`). The address will contain only `ids` of the corresponding country, city and street.

Let's add a new controller `AddressesController` and a method `new` which will show our form. We will load the list of countries in advance, but leave the list of cities and streets empty. In the `view` itself we need to take into account a few subtleties:
- All fields that will call Stimulus controller methods must be located inside a block with the parameter `<div data-controller=“controller_name”>`. It can be a one block for all fields, or several blocks, as you prefer.
- Each of the elements to be updated should be placed in separate `div` blocks, so that they can be identified and replaced via turbo stream.

In order to add a dynamic action to the country selection, we must add a `data-action` to this field:
```ruby
data: { action: 'change->addresses#country_change' }
```
This line tells `Stimulus` that when the `countries_id` select is changed (it works in the same way as `.on(“change”, ...)` from jQuery), the `country_change` method of the `addresses` controller should be called.
A similar parameter should be added for the list of cities, only with a different method name.

Now let's add a new Stimulus controller in the `app/javascript/controllers` directory. In the `country_change` method we will add Java Script code that makes a request to the server to the `addresses#country_change` endpoint (which we also need to add), and renders the Turbo Stream received in response. Note that we need to specify a special request format `text/vnd.turbo-stream.html`. In the rails controller, which will respond to this request, we need to initialize a new `address` (we will need it to create an empty form) and a new object `@cities` with a list of cities for the specified `country_id`.

Let's create a Turbostream template `country_change.turbo_stream.erb`. There is one more trick here, we want to render a `partial template`, which contains fields for the form. To do this we need to pass a form object to it, but we don't have it, it is left in the parent template which is not available in turbo stream. To get around this problem we create a new form using the `form_with` tag and an empty `@address` created in the rails controller, so that the generated html completely corresponds to the similar form from the main template.

Let's add similar controller methods and templates for the cities list and we can check how the form works.

### Findings
To be honest, after implementing a dynamic form using Hotwire, I have a lot of doubts about the applicability of this technology. There are several reasons for this:
-  For every dynamic action on the page we need to have two controllers (Rails and Stimulus), routing, partial view and turbostream view. Given that there can be many such elements in a large form, this is a huge amount of unnecessary code. Hotwire is rapidly evolving, not so long ago it only worked with POST requests and required a lot more crutches like swapping CSRF token in ajax request to generate form correctly, so there is hope that all this boilerplate can be avoided soon using new `data` tags. But for now it's a very time consuming process.
- The whole process of updating a form is very similar to what existed 20 years ago in the days of jQuery. We add a `javascript callback` that makes an ajax request and replaces a piece of html by `id`. Only in the days of jQuery this was done by a small script right in the html template, but now it takes several classes and files to do the same thing. The essence is the same, but much more complicated.
- Every action on a page when using Hotwire requires a request to the server. Imagine you have a busy application that processes 10,000
requests per minute. You switch to Hotwire and now you need to support 30,000 - 40,000 requests. Yes, they're smaller than a full page refresh, but it's still an extra significant load on the server. Plus, if you're hosted in the cloud, each request costs money and increasing your budget several times is not a good idea.
- The technology is new and there is very little documentation on the web on how to use it. To implement the simplest thing, you have to read 3-4 different articles in addition to the official documentation. At the same time, many articles are already outdated and contain incorrect information.

## Hotwire + broadcast
There is an option to use Turbo stream to update a part of the client page via websocket when some events on the server or a background task is executed. I have not looked into this feature because it works via ActionCable, which has performance issues as mentioned in the Evil Martians article [AnyCable: Action Cable on steroids](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids). I haven't found any documentation about whether it works through AnyCable yet. Most likely there will be support in the future and it'll be reasonable to try. If you want to do it now, there is [another article](https://railsnotes.xyz/blog/the-simplest-ruby-on-rails-and-hotwire-app-possible-beginners-guide).

