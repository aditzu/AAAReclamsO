"use strict";

var square = function(x) {return x*x;}
function Market(name){
    this.name = name;
}

function Markets() {
//    this.getMarkets = function(){
//                            Log("got invoked ");
//                            $.get("http://192.168.1.102:8090/markets/list/", function(data){
//                              Log("Pual");
//                              Log("data: " + data);
//                            });
//                            Log("After");
//                        };
}

function succes(data){
    Log("Pula");
    Log("data: " + data);
};

function getMarkets(){
                              Log("got invoked ");
                              $.get("http://192.168.1.102:8090/markets/list/", succes);
                              Log("After");
                        };
//
//$.get("http://192.168.1.102:8090/markets/list/", function(data){
//                              Log("Pual");
//                              Log("data: " + data);
//                            });

//Markets.prototype.getMarkets = function(){
//    Log("Before");
//    $.get("http://www.google.com/", function(data){
//        Log("data: " + data);
//    });
//        Log("After");
//
//};

var marks = new Markets();
