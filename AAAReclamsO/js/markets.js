"use strict";

function Market(name){
    this.name = name;
}

function Markets() {
    this.getMarkets = function(){
    Log("Called");
                            $.get("http://192.168.0.16:8090/markets/list/", function(data){
                              Log("data: " + JSON.stringify(data));
                            });
                            Log("Ended");
                        };
}

var marks = new Markets();
