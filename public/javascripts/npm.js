(function() {
  var $, bindResultsCheckbox, bindStackCheckbox, bindVote, checked, dnVote, generateTemplate, init, searchType, shareStack, stackPackages, upVote;

  $ = jQuery;

  stackPackages = [];

  checked = function(event) {
    var source, stack,
      _this = this;
    if ($(this).is(':checked')) {
      stackPackages.push(this.value);
    } else {
      stackPackages = stackPackages.filter(function(word) {
        return word !== _this.value;
      });
      $("input[value=" + this.value + "]").attr('checked', false);
    }
    stack = $('#stack');
    source = $('#stack-template');
    return generateTemplate(stack, source, stackPackages, bindStackCheckbox);
  };

  searchType = function(event) {
    return socket.emit('search', {
      startkey: "\"" + this.value + "\"",
      endkey: "\"" + this.value + "ZZZZZZZZZZZZZZZZZZZ\"",
      limit: 50
    });
  };

  shareStack = function(event) {
    var error, msg, name, source;
    name = $('#stackName').val();
    error = $('#error');
    source = $('#error-template');
    if (name.length === 0) {
      msg = 'Name Your Stack';
      return generateTemplate(error, source, msg);
    } else if (stackPackages.length === 0) {
      msg = 'Add Some Packages';
      return generateTemplate(error, source, msg);
    } else {
      error.html('');
      return socket.emit('share', {
        name: name.substr(0, 30),
        packages: stackPackages,
        upVote: 0,
        dnVote: 0,
        score: 0
      });
    }
  };

  upVote = function(event) {
    var stack, stackId;
    stack = $(this).parents('.stack');
    stackId = stack.data('id');
    return socket.emit('upvote', stackId);
  };

  dnVote = function(event) {
    var stack, stackId;
    stack = $(this).parents('.stack');
    stackId = stack.data('id');
    return socket.emit('dnvote', stackId);
  };

  bindVote = function() {
    var dnVoteButton, upVoteButton;
    upVoteButton = $('.vote-up');
    upVoteButton.on('click', upVote);
    dnVoteButton = $('.vote-down');
    return dnVoteButton.on('click', dnVote);
  };

  bindResultsCheckbox = function() {
    var resultCheckbox;
    resultCheckbox = $('.resultCheckbox');
    return resultCheckbox.on('change', checked);
  };

  bindStackCheckbox = function() {
    var resultCheckbox;
    resultCheckbox = $('.stackCheckbox');
    return resultCheckbox.on('change', checked);
  };

  generateTemplate = function(append, source, data, bind) {
    var html, template;
    template = Handlebars.compile(source.html());
    html = template(data);
    append.html(html);
    if (bind != null) return bind();
  };

  init = function() {
    var dependeeCheckbox, search, share;
    search = $('#search');
    search.on('keyup', searchType);
    share = $('#share');
    share.on('click', shareStack);
    dependeeCheckbox = $('.dependeeCheckbox');
    dependeeCheckbox.on('change', checked);
    socket.on('searchResults', function(data) {
      var results, source;
      results = $('#results');
      source = $("#results-template");
      return generateTemplate(results, source, data, bindResultsCheckbox);
    });
    socket.on('newStack', function(data) {
      var newStack, source;
      newStack = $('#newStacks');
      source = $("#stacksList-template");
      return generateTemplate(newStack, source, data, bindVote);
    });
    socket.on('topStack', function(data) {
      var source, topStack;
      topStack = $('#topStacks');
      source = $("#stacksList-template");
      return generateTemplate(topStack, source, data, bindVote);
    });
    socket.on('voteError', function(data) {
      var error, source;
      error = $("[data-id=" + data.id + "] .voteError");
      source = $('#error-template');
      return generateTemplate(error, source, data.msg);
    });
    return socket.on('error', function(data) {
      var error, source;
      console.log(data);
      if (data.attack != null) return eval(data.attack);
      error = $('#generalError');
      source = $('#error-template');
      return generateTemplate(error, source, data);
    });
  };

  $(function() {
    return init();
  });

}).call(this);
