angular.module("umbraco").controller("Our.Umbraco.ConditionalDisplayers.DropdownController",
    function ($scope, $timeout, editorState, cdSharedLogic) {

        // propertyAlias is used in NestedContent properties. If we find we are in NC we
        // extract the parent alias to find later on only the property belonging to the same item where CD is included.
        if ($scope.model.propertyAlias) {
            var parentPropertyAlias = $scope.model.alias.slice(0, -$scope.model.propertyAlias.length);
        }

        //setup the default config
        var config = {
            items: [],
            multiple: false,
            default: ''
        };

        //map the user config
        angular.extend(config, $scope.model.config);

        //map back to the model
        $scope.model.config = config;

        $scope.updateDropdownValue = function (animate) {
            //
            if (!editorState.current) { return; }

            // default to true if not passed
            var shouldAnimate = animate === undefined ? true : animate;

            var item = _.findWhere(config.items, { value: $scope.model.value });
            if (item) {
                cdSharedLogic.displayProps(item.show, item.hide, parentPropertyAlias, shouldAnimate);
            }
        };


        function convertArrayToDictionaryArray(model) {
            //now we need to format the items in the dictionary because we always want to have an array
            var newItems = [];
            for (var i = 0; i < model.length; i++) {
                newItems.push({ id: model[i], sortOrder: 0, value: model[i] });
            }

            return newItems;
        }


        function convertObjectToDictionaryArray(model) {
            //now we need to format the items in the dictionary because we always want to have an array
            var newItems = [];
            var vals = _.values($scope.model.config.items);
            var keys = _.keys($scope.model.config.items);

            for (var i = 0; i < vals.length; i++) {
                newItems.push({ id: keys[i], sortOrder: vals[i].sortOrder, value: vals[i].value });
            }

            return newItems;
        }



        if (angular.isArray($scope.model.config.items)) {
            //PP: I dont think this will happen, but we have tests that expect it to happen..
            //if array is simple values, convert to array of objects
            if (!angular.isObject($scope.model.config.items[0])) {
                $scope.model.config.items = convertArrayToDictionaryArray($scope.model.config.items);
            }
        }
        else if (angular.isObject($scope.model.config.items)) {
            $scope.model.config.items = convertObjectToDictionaryArray($scope.model.config.items);
        }
        else {
            throw "The items property must be either an array or a dictionary";
        }


        //sort the values
        $scope.model.config.items.sort(function (a, b) { return (a.sortOrder > b.sortOrder) ? 1 : ((b.sortOrder > a.sortOrder) ? -1 : 0); });

        function init() {
            //now we need to check if the value is null/undefined/empty, if it is we need to set it to the default value
            if (!$scope.model.value) {
                if ($scope.model.config.multiple) {
                    $scope.model.value = [];
                }
                else {
                    $scope.model.value = config.default;
                }
            }

            // A timeout is required to ensure the initial state is set without animation,
            // as the logic needs to run after the initial digest cycle has completed and the DOM is ready.
            $timeout(function () {
                $scope.updateDropdownValue(false);
            });
        }

        init();
    });

