﻿(function (abp, angular) {

    if (!angular) {
        return;
    }

    abp.ng = abp.ng || {};

    abp.ng.http = {
        defaultError: {
            message: 'An error has occurred!',
            details: 'Error detail not sent by server.'
        },

        logError: function (error) {
            abp.log.error(error);
        },

        showError: function (error) {
            if (error.details) {
                return abp.message.error(error.details, error.message || abp.ng.http.defaultError.message);
            } else {
                return abp.message.error(error.message || abp.ng.http.defaultError.message);
            }
        },

        handleTargetUrl: function (targetUrl) {
            location.href = targetUrl;
        },

        handleUnAuthorizedRequest: function (messagePromise, targetUrl) {
            if (messagePromise) {
                messagePromise.done(function () {
                    if (!targetUrl) {
                        location.reload();
                    } else {
                        abp.ng.http.handleTargetUrl(targetUrl);
                    }
                });
            } else {
                if (!targetUrl) {
                    location.reload();
                } else {
                    abp.ng.http.handleTargetUrl(targetUrl);
                }
            }
        },

        handleResponse: function (response, defer) {
            var originalData = response.data;

            if (originalData.success === true) {
                response.data = originalData.result;
                defer.resolve(response);

                if (originalData.targetUrl) {
                    abp.ng.http.handleTargetUrl(originalData.targetUrl);
                }
            } else if (originalData.success === false) {
                var messagePromise = null;

                if (originalData.error) {
                    messagePromise = abp.ng.http.showError(originalData.error);
                } else {
                    originalData.error = defaultError;
                }

                abp.ng.http.logError(originalData.error);

                response.data = originalData.error;
                defer.reject(response);

                if (originalData.unAuthorizedRequest) {
                    abp.ng.http.handleUnAuthorizedRequest(messagePromise, originalData.targetUrl);
                }
            } else { //not wrapped result
                defer.resolve(response);
            }
        }
    }

    var abpModule = angular.module('abp', []);

    abpModule.config([
        '$httpProvider', function ($httpProvider) {
            $httpProvider.interceptors.push(['$q', function ($q) {

                return {

                    'request': function (config) {
                        if (config.url.indexOf('.cshtml') !== -1) {
                            config.url = abp.appPath + 'AbpAppView/Load?viewUrl=' + config.url + '&_t=' + abp.pageLoadTime.getTime();
                        }

                        return config;
                    },

                    'response': function (response) {
                        if (!response.data || !response.data.__abp) {
                            return response;
                        }

                        var defer = $q.defer();
                        abp.ng.http.handleResponse(response, defer);
                        return defer.promise;
                    },

                    'responseError': function (ngError) {
                        if (!ngError.data || !ngError.data.__abp) {
                            abp.ng.http.showError(abp.ng.http.defaultError);
                            return ngError;
                        }

                        var defer = $q.defer();
                        abp.ng.http.handleResponse(ngError, defer);
                        return defer.promise;
                    }

                };
            }]);
        }
    ]);

    abp.event.on('abp.dynamicScriptsInitialized', function () {
        abp.ng.http.defaultError.message = abp.localization.abpWeb('DefaultError');
        abp.ng.http.defaultError.details = abp.localization.abpWeb('DefaultErrorDetail');
    });

})((abp || (abp = {})), (angular || undefined));