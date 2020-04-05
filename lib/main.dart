import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pay/sems.dart' as sems;

String merchantId="annaunniv123456";
var list;

void main() => runApp(LoginPage());

class LoginPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'Sems - Payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar:AppBar(
          title:Text("SEMS"),
        ),
        body:Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _showPassword = false;
  bool _shownewpass = false;
  bool _showconfirmpass = false;
  bool _validRoll = true;
  var _form = 'login';
  static DateTime selectedDate = DateTime(1998,1,1);
  var dateFormat = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';

  TextEditingController roll = new TextEditingController();
  TextEditingController forgotroll = new TextEditingController();
  TextEditingController password = new TextEditingController();
  TextEditingController newpass = new TextEditingController();
  TextEditingController confirmpass = new TextEditingController();

  static String pwd="";
  static bool isLoading=false;

  @override
  void initState(){
    super.initState();
    selectedDate = DateTime(1998,1,1);
  }

  _validateCredentials(rollno,pass) async{
    final response = await http.get("http://localhost/testing/sems/login.php?roll=$rollno");
    if(response.statusCode==200){
      list = json.decode(response.body);
      pwd = list['password'];
    }else{
      list=[];
    }
  }

  _verifyUser(rollno) async{
    final response = await http.get("http://localhost/testing/sems/login.php?roll=$rollno&dob=$dateFormat");
    if(response.statusCode==200){
      var res = json.decode(response.body);
      if(res['roll']==rollno.toString() && rollno.toString()!=''){
          final snackbar = SnackBar(content: Text("Verification Successful"));
          Scaffold.of(context).showSnackBar(snackbar);
          // Navigator.push(context,MaterialPageRoute(builder: (context)=>sems.Sems(roll.text)));
          setState((){
           isLoading = false;
           _form='changePass'; 
          });
      }else{
          setState(()=> isLoading = false);
          final snackbar = SnackBar(content: Text("Verification Failed"));
          Scaffold.of(context).showSnackBar(snackbar);
        }
    }else{
      list=[];
    }
    return false;
  }

  _resetPass(rollno,newpass,confirmpass) async{
    if(newpass==confirmpass){
      var bytes1 = utf8.encode(newpass);
      var pass = sha256.convert(bytes1);
      final response = await http.get("http://localhost/testing/sems/reset.php?roll=$rollno&pass=$pass");
      if(response.statusCode==200){
       if(response.body.trim().toString() == 'Success'){
         setState((){
           isLoading = false;
           _form = 'login';
         });
         final snackbar = SnackBar(content: Text("passwords changed successfully"));
        Scaffold.of(context).showSnackBar(snackbar);
       }else{
         print(response.body);
         setState((){
           isLoading = false;
         });
        final snackbar = SnackBar(content: Text("Error while changing password"));
        Scaffold.of(context).showSnackBar(snackbar);
       }
      }
    }else{
      setState(()=> isLoading = false);
      final snackbar = SnackBar(content: Text("passwords didn't match"));
      Scaffold.of(context).showSnackBar(snackbar);
    }
  }
  Widget login(){
    var  loginWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children:<Widget>[
              ListTile(
                title:Center(
                  child:Text("LOGIN"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Divider(
                    color: Colors.blue,
                    height: 5,
                    thickness: 2,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: 70,
                  top: 20,
                  right: 70,
                  bottom: 20,
                ),
                child:Column(
                  children:<Widget>[
                    TextField(
                      controller: roll,
                      maxLength: 10,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:"Roll Number",
                        hintText: "Enter Roll Number",
                        counter: Container(),
                        errorText: this._validRoll ? null : "Please enter a roll number",
                      ),
                    ),
                    TextField(
                      controller: password,
                      obscureText: !this._showPassword,
                      decoration: InputDecoration(
                        labelText:"Password",
                        hintText: "Enter Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.remove_red_eye,
                            color: this._showPassword ? Colors.blue:Colors.grey,
                          ), 
                          onPressed: (){
                            setState(() => this._showPassword = !this._showPassword);
                          }
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                      child: RaisedButton(
                        child: GestureDetector(
                          child:Text("Login"),
                          onTap: () async{
                            setState(()=> isLoading = !isLoading);
                            var bytes1 = utf8.encode(password.text);
                            var pass = sha256.convert(bytes1);
                            setState(()=> isLoading = true);
                            await _validateCredentials(roll.text,pass);
                            if(pwd == pass.toString() && password.text.toString().length!=0){
                              final snackbar = SnackBar(content: Text("Login Successful"));
                              Scaffold.of(context).showSnackBar(snackbar);
                              Navigator.push(context,MaterialPageRoute(builder: (context)=>sems.Sems(roll.text)));
                              setState(()=> isLoading = false);
                            }else{
                              setState(()=> isLoading = false);
                              final snackbar = SnackBar(content: Text("Login Failed"));
                              Scaffold.of(context).showSnackBar(snackbar);
                            }
                          },
                        ),
                        onPressed: () async{
                          var bytes1 = utf8.encode(password.text);
                          var pass = sha256.convert(bytes1);
                          setState(()=> isLoading = true);
                          await _validateCredentials(roll.text,pass);
                          if(pwd == pass.toString()){
                            final snackbar = SnackBar(content: Text("Login Successful"));
                            Scaffold.of(context).showSnackBar(snackbar);
                            Navigator.push(context,MaterialPageRoute(builder: (context)=>sems.Sems(roll.text)));
                            setState(()=> isLoading = false);
                          }else{
                            setState(()=> isLoading = false);
                            final snackbar = SnackBar(content: Text("Login Failed"));
                            Scaffold.of(context).showSnackBar(snackbar);
                          }
                        },
                        color: Colors.blue,
                        textColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top:10),
                      child: GestureDetector(
                        child:Text('Forgot Password ?',style:TextStyle(color: Colors.blue,decoration:TextDecoration.underline)),
                        onTap:(){
                          setState((){
                            _form='forgot';
                          });
                        }
                      ),
                    )
                  ]
                ),
              ),
            ]
          );
          setState(() {
            isLoading=false;
          });
          return loginWidget;
  }

Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1990, 1),
        lastDate: DateTime(2000));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        dateFormat = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
      });
  }
  Widget forgot(){
    var  forgotWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children:<Widget>[
              ListTile(
                title:Center(
                  child:Text("Forgot Password"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Divider(
                    color: Colors.blue,
                    height: 5,
                    thickness: 2,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: 70,
                  top: 20,
                  right: 70,
                  bottom: 20,
                ),
                child:Column(
                  children:<Widget>[
                    TextField(
                      controller: forgotroll,
                      maxLength: 10,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:"Roll Number",
                        hintText: "Enter Roll Number",
                        counter: Container(),
                        errorText: this._validRoll ? null : "Please enter a roll number",
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        RaisedButton(
                          onPressed: () => _selectDate(context),
                          child: Text('Select date of birth',style: TextStyle(color:Colors.white),),
                          color: Colors.blue,
                        ),
                        Text(' '),
                        Expanded(child: Center(child: Text(dateFormat),))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                      child: Row(children: <Widget>[
                        RaisedButton(
                        child: GestureDetector(
                          child:Text("Back"),
                          onTap: () {
                            setState(() {
                              _form='login';
                            });
                          },
                        ),
                        onPressed: () {
                          
                        },
                        color: Colors.blueAccent,
                        textColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      ),
                        Expanded(child: Align(alignment: Alignment.centerRight,
                        child: RaisedButton(
                          child: GestureDetector(
                            child:Text("Reset Password"),
                              onTap: () async{
                                setState(()=> isLoading = true);
                                await _verifyUser(forgotroll.text);
                              },
                            ),
                            onPressed: () async{
                              setState(()=> isLoading = true);
                              await _verifyUser(forgotroll.text);
                            },
                            color: Colors.redAccent,
                            textColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          ),
                        ))
                        
                      ],)
                    ),
                  ]
                ),
              ),
            ]
          );
          setState(() {
            isLoading=false;
          });
          return forgotWidget;
  }

Widget newPass(){
  var  passWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children:<Widget>[
              ListTile(
                title:Center(
                  child:Text("New Password"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Divider(
                    color: Colors.blue,
                    height: 5,
                    thickness: 2,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: 70,
                  top: 20,
                  right: 70,
                  bottom: 20,
                ),
                child:Column(
                  children:<Widget>[
                    TextField(
                      controller: newpass,
                      obscureText: !this._shownewpass,
                      decoration: InputDecoration(
                        labelText:"New Password",
                        hintText: "Enter new password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.remove_red_eye,
                            color: this._shownewpass ? Colors.blue:Colors.grey,
                          ), 
                          onPressed: (){
                            setState(() => this._shownewpass = !this._shownewpass);
                          }
                        ),
                      ),
                    ),
                    TextField(
                      controller: confirmpass,
                      obscureText: !this._showconfirmpass,
                      decoration: InputDecoration(
                        labelText:"Confirm Password",
                        hintText: "Enter Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.remove_red_eye,
                            color: this._showconfirmpass ? Colors.blue:Colors.grey,
                          ), 
                          onPressed: (){
                            setState(() => this._showconfirmpass = !this._showconfirmpass);
                          }
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                      child: Row(children: <Widget>[
                        RaisedButton(
                        child: GestureDetector(
                          child:Text("Cancel"),
                          onTap: () {
                            setState(() {
                              isLoading=true;
                              _form='login';
                            });
                            setState(() {
                              isLoading=false;
                            });
                          },
                        ),
                        onPressed: () {
                          setState(() {
                              isLoading=true;
                              _form='login';
                            });
                            setState(() {
                              isLoading=false;
                            });
                        },
                        color: Colors.blueAccent,
                        textColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      ),
                        Expanded(child: Align(alignment: Alignment.centerRight,
                        child: RaisedButton(
                          child: GestureDetector(
                            child:Text("Set New Password"),
                              onTap: () async{
                                setState(()=> isLoading = !isLoading);
                                setState(()=> isLoading = true);
                                await _resetPass(forgotroll.text,newpass.text,confirmpass.text);
                              },
                            ),
                            onPressed: ()async{
                              setState(()=> isLoading = !isLoading);
                              setState(()=> isLoading = true);
                              await _resetPass(forgotroll.text,newpass.text,confirmpass.text);
                            },
                            color: Colors.redAccent,
                            textColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          ),
                        ))
                        
                      ],)
                    ),
                  ]
                ),
              ),
            ]
          );
          setState(() {
            isLoading=false;
          });
          return passWidget;
}
  @override
  Widget build(BuildContext context) {
    return isLoading?Center(
      child:CircularProgressIndicator(),
    ):Center(
      child:Container(
        width: 500,
        height: 330,
        child:Card(
          elevation: 10,
          child: _form=='login'?login():_form=='forgot'?forgot():newPass(),
        ),
      )
    );
  }
}