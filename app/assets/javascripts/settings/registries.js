(function (window) {
  var dom = {
    URL_GROUP: '.form-group-url',
    URL_INPUT: '.url',
    URL_INVALID_INSECURE: '.invalid-insecure',
    URL_INVALID_FORMAT: '.invalid-format',
    CERTIFICATE_GROUP: '.form-group-certificate',
  };

  function RegistryForm(el) {
    this.$el = $(el);
    this.$url = this.$el.find(dom.URL_INPUT);
    this.$urlGroup = this.$el.find(dom.URL_GROUP);
    this.$invalidUrlFormat = this.$el.find(dom.URL_INVALID_FORMAT);
    this.$invalidUrlInsecure = this.$el.find(dom.URL_INVALID_INSECURE);
    this.$certificateGroup = this.$el.find(dom.CERTIFICATE_GROUP);

    this.events();
  }

  RegistryForm.prototype.events = function () {
    this.$el.on('input', dom.URL_INPUT, this.validate.bind(this));
  }

  RegistryForm.prototype.toggleCertificateField = function (isSecure) {
    this.$certificateGroup.toggleClass('hide', !isSecure);
  }

  RegistryForm.prototype.validate = function () {
    this.clearValidation();

    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }

    this.timeoutId = setTimeout(function () {
      var urlValue = this.$url.val();
      var valid = true;

      try {
        var url = new URL(urlValue);
        var isHttps = url.protocol === 'https:';

        valid = (url.protocol === 'http:' || isHttps) && !!url.host;

        this.toggleCertificateField(isHttps);
      } catch (error) {
        valid = false;
      }

      if (valid) {
        this.checkInsecure();
      }

      // avoid validation when it's empty
      if (!this.$url.val()) {
        valid = true;
      }

      this.$urlGroup.toggleClass('has-error', !valid);
      this.$invalidUrlFormat.toggleClass('hide', valid);
      this.timeoutId = null;
    }.bind(this), 1500);
  }

  RegistryForm.prototype.clearValidation = function () {
    this.$urlGroup.removeClass('has-error');
    this.$invalidUrlFormat.addClass('hide');
    this.$invalidUrlInsecure.addClass('hide');
  }

  RegistryForm.prototype.checkInsecure = function () {
    var url = this.$url.val();
    var isSecure = url.indexOf('https') === 0;

    this.$el.find(dom.URL_INVALID_INSECURE).toggleClass('hide', isSecure);
  }

  window.RegistryForm = RegistryForm;
}(window));