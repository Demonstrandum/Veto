# Veto
Simple polling site writen in Ruby, using Sinatra.

![2018-11-20-182258_1366x768_scrot](https://user-images.githubusercontent.com/26842759/48796535-cc17f700-ecf7-11e8-9167-eef5c086fe6e.png)
# Running Locally
First of all, one need the Ruby programming language installed. One can install this from the official [Ruby Website](https://www.ruby-lang.org/en/) or one'll most likely have it available through one's main package manager.

One need to use Ruby Gems to install Bundler, gems should come with one's installation of Ruby.
In one's terminal, type:
```shell
gem install bundler
```
Make sure one adds the .gem bin/ path to one's `$PATH` variable in one's main shell.
e.g. in one's `~/.bashrc` add
```shell
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
```
Then restart one's shell session, by typing `bash` or whatever shell one uses.

One needs to make sure one has `eventmachine` installed, for the `thin` server to work.
One does this by running:
```shell
gem install eventmachine
```
If one gets errors about failing to build native extensions, read up in libraries needed to build (g++, gcc, musl-dev, make libstdc++, etc). Read about it here https://github.com/eventmachine/eventmachine/wiki/Building-EventMachine.

Now one clones this repo, or fork it, depending on whether one wants to simply run the server, or contribute to the site, respectively. Either simply type:
```shell
git clone https://github.com/Demonstrandum/Veto.git
```
in one's shell to clone it, or fork it by pressing the fork button on this webpage, then clone that fork instead, for which one can later submit a pull request. One now wants to enter this directory, one does this by simply typing:
```shell
cd Veto
```

---

After this, one would want to install the gems from the `Gemfile` file, this one does by running:
```shell
bundle install
```
whilst in the root directory of this repo.

---

One should now be ready to run the server locally! Whilst in the Veto/ directory, kindly type:
```shell
bundle exec ruby server.rb
```
One should see Sinatra take the stage with backup from Thin, (their words). If not, and one's getting issues with `eventmachine` and/or trouble finding the Thin server, please revisit the steps above concerning `eventmachine` installation.

Otherwise, one should be fine, now one can access [localhost:8080](http://localhost:8080/), and one can make any changes locally. One only needs to restart the server if one has made changes to the `server.rb` file, otherwise any changes to any other .erb, .js, .css files, etc. should not require a restart.


![2018-11-20-182338_1366x768_scrot](https://user-images.githubusercontent.com/26842759/48796534-cc17f700-ecf7-11e8-8cf5-5f073f411e44.png)

## Welp
Someone help me make it look pretty. I'm too lazy to write heaps of CSS again
