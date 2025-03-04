# Startup
Что бы посмотреть, как работает приложение нужны:
- ruby 3.3.5
- rails 8.0.1
- sqlite

Для запуска:
- `git pull`
- `bundle install`
- `bundle exec rails db:create db:migrate db:seed`
- `bundle exec rails css:install:bootstrap`
- `bundle exec rails s`

Сайт доступен на [http://127.0.0.1:3000](http://127.0.0.1:3000)

# Test hotwire app

В этой статье я хочу рассказать про эксперименты с Hotwire - новой технологие для написания динамический one-page приложений без использовая сложных frontend фреймворков. Основная идея Hotwire состоит в том, что при каком-либо действии на странице отправляется запрос на сервер, где рендерится новый кусочек html документа, который отправляется обратно и заменяет или дополняет имеющуюся страницу.

Технология состоит из нескольких компонентов:
- Turbo:
    - Turbo Drive отвечает за замену частей HTML на странице и предотвращает полную перезагрузку страницы при отправке запроса. Фактически движок на котором работает вся технология
    - Turbo Frames позволяет разделять страницы на отдельные части, которые могут быть изменены отдельно от всей страницы
    - Turbo Streams добавляет гибкости в обработке ответов сервера. С ними можно не только заменить один фрейм или всю страницу, но и выполнить множество различных операций при одном запросе.
    - Turbo Native в будущем будет использоваться для создания мобильный приложений, но пока еще в разработке.
- Stimulus - JS библиотека которая выполняет замену частей html документов и выполняет запросы на сервер.

## Простейший пример - перезагрузка всей страницы.

Я буду использовать bootstrap что бы добавить стилей на страницу. Для этого создаю приложение с директивой `--css=bootstrap`
Добавим панель навигации в наш `app/views/layouts/application.html.erb`. А так же первый route и контроллер для статичных страниц `app/controllers/pages_controller.rb`.

Запустим наше приложение и посмотрим, что происходит при нажатии на ссылки на панели навигации. Если открыть панель разработчика в браузере и посмотреть сетевые запросы, можно увидеть что страница не перезагружается полностью. Вместо этого TurboJS выполняет запрос на сервер, загружает только html внутри тегов `<body></body>` и заменяет его. При этом css стили, JS скриты как и весь layout не меняются. Фактически TurboDrive работает в rails 7/8 автоматически и это можно даже не заметить.

## Чуть интереснее - TurboFrames

Откроем вторую ссылку в приложении. Если посмотреть на код этой страницы можно увидеть, что параграф статьи теперь окружен тегами `turbo_frame_tag` с идентификатором `current_paragraph`. Это тот самый turbo_frame который мы будем менять, причем фрейм меняется на фрейм, поэтому в новом шаблоне, который вернет контроллер тоже должен быть `turbo_frame` с таким же идентификатором. Для этого мы используем partial шаблоны, которые и будем возвращать. Нам понадобится еще один эндпоинт в контроллере: `turbo_frame_change` на который мы будем отправлять идентификатор нужного параграфа, и который будет возвращать соответствующий фрейм. Откройте еще раз панель разработчика в браузере и убедитесь, что часть страницы, которая не окружена `turbo_frame` тэгами не изменяется и не возвращается при нажатии на ссылку. Что бы TurboDrive понимал, какой именно фрейм мы хотим поменять, нам нужно рассказать ему об этом, добавив ссылке параметр `data-turbo-frame` все остальное Rails сделает за нас при помощи своей знаменитой магии!

Турбофреймы позволяют нам динамически менять части страницы, но их область применения весьма не велика. Мы можем только поменять один фрейм за запрос на такой же фрейм, но с другим контентом. У нас нет возможности менять несколько фреймов, или добавлять что-то в начало или конец. Только менять часть html страницы целиком.

## Больше гибкости - Turbo streams

TurboStream - это особый формат запроса, который позволяет возвращать особый turbo_stream view с описанием изменений которые необходимо произвести на странице. TurboStream может работать как обычный http запрос, так и через web socket, меняя контент на клиентской странице при возникновении какого-то события на сервере.

Создадим новый контроллер `TurboStreamsController` его функционал будет очень похож на предыдущий, поэтому проще будет разделить контексты. Здесь нам протребуется два эндпоинта `init`, который мы будем открывать первым по ссылке в меню навигации и `call`, который будет обрабатывать `turbo_stream` запросы. Обратите внимание на формат http запроса, теперь этой `turbo_stream` и соответсвенно такой формат должен быть использован при его вызове. Для этого нам необходимо добавить параметр `data: {turbo_stream: true}` к ссылкам, которые мы используем. Далее можно увидеть, что мы инициализируем переменные, которые потом будут использоваться в `turbo_stream` шаблоне. Это дает нам достаточно большие возможности по добавлению различной логики на страницу.
Мы можем возвращать шаблон напрямую из контроллера, если он небольшой (`render turbo_stream: turbo_stream.action ...`), либо использовать отдельный файл. Согласно стандартному наименованию, наш шаблон имеет такое же название, как и метод контроллера, и расширение `turbo_stream.erb`. Давайте откроем файл и посмотрим, что там есть. Мы обрабатываем два двействия:
1. Меняем содержимое html элементам с id `paragrap_#{@old_paragraph}` на содержимое partial шаблона. Обратите внимание, что нам не нужны даже turbo_frames. Мы можем работать с любыми html элементами, которые можем идентифицировать, использую id или class.
2. Мы добавляем запись после div c `id="logs"`.

Таким образом, при помощи `turbo_streams` мы можем выполнять несколько действий за один запрос и динамически менять разные жлементы страницы. Причем не только заменять целиком, но и удалять, дописывать что-то в начало или конец, и.т.д.

## Stimulus, а так же боль, страдание и пример из реальной жизни
До сих пор мы работали с Turbo достаточно легко, потому что использовали ссылки и без проблем отправляли запросы на сервер. Однако в реальной жизни у нас есть множетсво пользовательских действий, которые должны динамически обрабатываться клиентом, но при этом не являются нажатием на ссылку и не отправляют запрос автоматически. Для решения этой проблемы Rails предлагает Stimulus controllers. Stimulus - это JavaScript библиотека, которая позволяет вызывать функции, указанные в html параметре `data-action`. Давайте посмотрим, как это работает на примере создания динамической формы для адреса. Мы добавим несколько `select` полей, когда пользователь выбирает страну, мы будем подгружать список городов для этой страны, а когда выбирает город - список улиц для города.

Для начала создадим соответствующие модели: `Counrty`, `City`, `Street` и `Address`. Заполним их простыми сидами(`db/seeds.rb`). Адрес будет содержать только `id` соответсвующих страны, города и улицы.

Добавим новый контроллер `AddressesController` и метод `new` который будет показывать нашу форму. Список стран мы загрузим заранее, а вот список городов и улиц оставим пустым. В самом `view` необходимо учесть несколько тонкостей:
- Все поля, которые будут вызывать методы `Stimulus controller` должны находить внутри блока с параметром `<div data-controller="controller_name" >`. Он может быть один на все поля, или несколько, как удобнее.
-  Каждый из элементов, который мы будем обновлять надо положить в отдельныe `div` блоки, что бы их можно было идентифицировать и заменить через turbo stream.

Для того, что бы добавить динамическое действие на выбор страны, добавим этому полю `data-action`:
```ruby
data: { action: 'change->addresses#country_change' }
```
Эта строка, говорит `Stimulus`, что при выполнении действия `change` (аналог `.on("change", ...)` из JQuery) необходимо вызвать метод `country_change` контроллера `addresses`. Аналогичный параметр надо добавить и для списка городов, только с другим именем метода.

Теперь добавим в директории `app/javascript/controllers` новый Stimulus controller, в методе `country_change` мы добавим Java Script код, который делает запрос на сервер к эндпоинту `addresses#country_change` (который нам так же надо добавить), и рендерит полученный в ответ Turbo Stream. Обратите внимание, что нам нужно указать особый формат запроса `text/vnd.turbo-stream.html`. В rails контроллере, который будет отвечать на этот запрос надо надо инициализировать новый адрес (он нам поадобиться что бы создать пустую форму) и новый объект `@cities` со списком городов для указанного `country_id`.

Создадим шаблон Turbostream `country_change.turbo_stream.erb`. Тут есть еще одна хитрость, мы хотим отрендерить `partial template`, который содержит поля для формы. Для этого в него надо передать объект формы, но его у нас нет, он остался в родительском шаблоне который не доступен в turbo stream. Что бы обойти эту проблему мы создаем новую форму через тэг `form_with`, используя пустой адрес, созданный в rails контроллере, что бы сгенерированный html полностью соответствовал аналогичной форме из основного шаблона.

Добавим аналогичные методы контроллеров и шаблоны для списка городов и можно проверять, как работает форма.

### Выводы
Честно говоря, после реализации динамической формы при помощи Hotwire у меня появились большие сомнения в применимости данной технологии. На это есть несколько причин:
-  На каждое динамической действие на странице нам нужно иметь два контроллера Rails и Stimulus, роутинг, partial view и turbostream view. С учетом того, что в большой форме таких элементов может быть множество - это огромное количество лишнего кода. Hotwire быстро развивается, еще недавно он работал только с POST запросами и требовал гораздо больше костылей, вроде подмены CSRF токена в ajax запросе для правильной генерации формы, так что есть надежда что весь этот бойлерплейт вскоре можно будет сохранить используя новые `data` тэги. Но пока что это очень трудоемкий процесс.
- Весь процесс обновления формы очень похож на тот, что существовал 20 лет назад во времена JQuery. Мы добавляем `javascript callback`, который делает ajax запрос и заменяет кусок html по `id`. Только во времена JQuery это делалось небольшим скриптом прямо в html шаблоне, а теперь на это же действие требуется несколько классов и файлов. Суть та же, но гораздо сложнее.
- Каждое действие на странице при использовании Hotwire требует запроса к серверу. Представьте, что у вас нагруженное приложение, которое обрабатывает 10 000
запросов в минуту. Вы переходите на Hotwire и теперь вам надо поддерживать 30-40 тысяч запросов. Да, они меньше чем полное обновление страницы, но все равно это лишняя существенная нагрузка на сервер. К тому же если вы хоститесь в облаке, то каждый запрос стоит денег и увеличивать бюджет в несколько раз - не самая лучшая идея.
- Технология новая и в сети очень мало документации, как ей пользоваться. Для простейших вещей приходится перечитывать 3-4 разных статьи дополнительно к официальной документации. При этом многие статьи уже устарели и несут неверную информацию.

## Hotwire + broadcast
Существует возможность использовать Turbo stream что бы обновлять часть клиентской страницы через websocket при каких-то событиях на сервере или выполении фоновой задачи. Я не стал разбираться с этой возможностью, поскольку она работает через ActionCable у которо есть проблемы с производительностью, как указано в статье Марсиан [AnyCable: Action Cable on steroids](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids). Никакой документации про то, работает ли это через AnyCable я пока не нашел. Скорее всего в будущем поддержка появится и можно будет посмотреть как это работает. Если хочется посмотреть сейчас, есть [другая статья](https://railsnotes.xyz/blog/the-simplest-ruby-on-rails-and-hotwire-app-possible-beginners-guide)
