[IMPROVED and UPDATED]
----------------

[A cookbook of engineyard](https://github.com/engineyard/ey-cloud-recipes/tree/master/cookbooks/elasticsearch) hasn't been updated for a long time. Meanwhile, [an official cookbook](https://github.com/elasticsearch/cookbook-elasticsearch) is frequently updated. This cookbook is selectively combined with both for EngineYard Utility instances.  

Note that this cookbook is for single instance use.

[IMPROVED POINTS]
----------------

* Upgrade to elasticsearch `1.2.1` (latest version as of 2014/6/4) with `jdk1.7`.

* According to chef convention, `node['elasticsearch']['abc']` is used instead of `node[:elasticsearch_abc]` or `node.elasticsearch[:version]`. And updated `attributes/default.rb` is mainly derived from the official cookbook.

* `templates/default/elasticsearch.in.sh.erb` is mainly from EY cookbook. The official cookbook uses `elasticsearch-env.sh.erb` for some reasons but don't use it.

* init.d script (`templates/default/elasticsearch.init.erb`) from the official cookbook is introduced and `templates/default/elasticsearch.monitrc.erb` is updated together. Importantly this init script allows to run elasticsearch server as elasticsearch user not root.

* `templates/default/elasticsearch.yml.erb` is selectively updated by reference to the official elasticsearch.yml. It is still in a half-way.

* `recipes/default.rb` is updated in the following. 

  * Create elasticsearch user (uid: 61021) and elasticsearch group
  * Create service (init.d/script) 
  * Install jdk7 (actually installed 1.7.0_09) 
  * Change owner/group of the relevant directories to `elasticsearch` from `root`
  * Directory location as follows ( don't use `/usr/share` or `/usr/local` )

| Directory                        | File                     | Memo                                   |
| -------------------------------- | ------------------------ | -------------------------------------- |
| /usr/lib/elasticsearch           |                          | home directory                         |
| /usr/lib/elasticsearch/config    | elasticsearch.yml        | specified in `elasticsearch.in.sh.erb` |
| /usr/lib/elasticsearch/config    | logging.yml              | specified in `elasticsearch.yml`       |
| /usr/lib/elasticsearch/config    | elasticsearch.in.sh.erb  | specified in `init.d/elasticsearch`    |
| /usr/lib/elasticsearch/plugins   |                          | plugins                                |
| /data/elasticsearch/data         | index files              | because /data is persistent            |
| /data/elasticsearch/logs         | log files                | because /data is persistent            |

[TODO]
-------

* `engineyard.yml` is still messy. `print_value` method in the official cookbook will be copied.
* installing plugins should be easier.

The following is an original README.md.  


Elasticsearch Cookbook for AppCloud
---------------

You know, for Search

So, we build a web site or an application and want to add search to it, and then it hits us: getting search working is hard. We want our search solution to be fast, we want a painless setup and a completely free search schema, we want to be able to index data simply using JSON over HTTP, we want our search server to be always available, we want to be able to start with one machine and scale to hundreds, we want real-time search, we want simple multi-tenancy, and we want a solution that is built for the cloud.

"This should be easier", we declared, "and cool, bonsai cool".

[elasticsearch][2] aims to solve all these problems and more. It is an Open Source (Apache 2), Distributed, RESTful, Search Engine built on top of [Lucene][1].

Dependencies
--------

  * Your application should use gems(s) such as [tire][5],[rubberband][3],[elastic_searchable][6] or lastly for JRuby users there is [jruby-elasticsearch][4].

Using it
--------

  * There is two ways to run this recipe.  By default you can use the 'default' recipe and use this in an clustered configuration that requires utility instances.  Alternatively you can use the alternate recipe called 'non_util' which will configure your app_master/solo instance to have elasticsearch.  You would add to main/recipes/default.rb the following,

``include_recipe "elasticsearch::non_util"``  

  * Otheriwse you would do the following

``include_recipe "elasticsearch"``  

  * Now you should upload the recipes to your environment,
  
``ey recipes upload -e <environment>`` 

  * If you picked the non_util recipe you can ignore naming your utility instances.  Upload the recipe, click apply and you should find the neccesary things done;otherwise name your utility instances like below.
  
  * Add an utility instance with the following naming scheme(s)
      * elasticsearch_0
      * elasticsearch_1
      * elasticsearch_2
      * ...

  * Produce /data/#{appname}/shared/config/elasticsearch.yml on all instances so you can easily parse/configure elasticsearch for your usage.


Verify
-------

On your instance, run: 

    curl localhost:9200

Results should be simlar to:

    {
      "ok" : true,
      "name" : "Charles Xavier",
      "version" : {
        "number" : "0.18.2",
        "snapshot_build" : false
      },
      "tagline" : "You Know, for Search"
     ...
    }

Plugins
--------

Rudamentary plugin support is there in a definition.  You will need to update the template for configuration options for said plugin; if you wish to improve this functionality please submit a pull request.  

Examples: 

``es_plugin "cloud-aws" do``
``action :install``
``end``

``es_plugin "transport-memcached" do``
``action :remove``
``end``


Caveats
--------

plugin support is still not complete/automated.  CouchDB and Memcached plugins may be worth investigtating, pull requests to improve this.

Backups
--------

None automated, regular snapshot should work.  If you have a large cluster this may complicate things, please consult the [elasticsearch][2] documentation regarding that.

Warranty
--------

This cookbook is provided as is, there is no offer of support for this
recipe by Engine Yard in any capacity.  If you find bugs, please open an
issue and submit a pull request.

[1]: http://lucene.apache.org/
[2]: http://www.elasticsearch.org/
[3]: https://github.com/grantr/rubberband
[4]: https://github.com/jordansissel/jruby-elasticsearch/
[5]: https://github.com/karmi/tire
[6]: https://github.com/wireframe/elastic_searchable/
