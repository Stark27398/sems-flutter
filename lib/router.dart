import 'package:flutter/material.dart';
import 'package:pay/main.dart' as main;
import 'package:pay/sems.dart' as sems;

class Router{
  static const String loginPageRoute = "/";
  static const String semsPageRoute = "/sems";

  static Route<dynamic> generateRoute(RouteSettings settings){
    switch(settings.name){
      case loginPageRoute:
        return MaterialPageRoute(builder: (_)=>main.Home());
      case semsPageRoute:
        var data = settings.arguments as String;
        return MaterialPageRoute(builder: (_)=>sems.Sems(data));
      default:
        return MaterialPageRoute(builder: (_)=>main.Home());
    }
  }
}