import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:pay/main.dart' as main;

bool onPay = true;
bool isLoading=false;
bool isPaid = false;
String roll="";
var transactions;
var fees;
var statusColors;
var statusText;
String total="";

class ReLoadFee extends StatefulWidget {
  final String rollno;
  ReLoadFee(this.rollno);

  @override
  _ReLoadFeeState createState() => _ReLoadFeeState();
}

class _ReLoadFeeState extends State<ReLoadFee> {
  
  @override
  void initState(){
    super.initState();
    Timer.run(() {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>Sems(widget.rollno)), (route) => false);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
class Sems extends StatefulWidget {

  final String rollno;
  const Sems(this.rollno);

  @override
  _SemsState createState() => _SemsState();
}

class _SemsState extends State<Sems> {

  _loadFees() async{
    final response = await http.get("http://localhost/testing/sems/student.php?roll=$roll");
    if(response.statusCode==200){
      fees = json.decode(response.body);
      if(fees['status_id']=='0' || fees['status_id']=='-1'){
        setState(()=>isPaid = false);
      }else{
        setState(()=>isPaid = true);
      }
    }else{
      fees=[];
    }
    return fees;
  }
  _loadTransactions() async{
    final response = await http.get("http://localhost/testing/sems/transactions.php?roll=$roll");
    if(response.statusCode==200){
      transactions = json.decode(response.body);
    }else{
      transactions=[];
    }
    return transactions;
  }

  @override
  void initState(){
    roll=widget.rollno;
    setState(() {
      isLoading=true;
    });
    if(onPay){
      _loadFees().then((result){
        setState(() {
          fees=result;
        });
        setState(() {
          isLoading=false;
        });
      });
    }else{
      _loadTransactions().then((result){
        setState(() {
          transactions=result;
        });
        setState(() {
          isLoading=false;
        });
      });
    }
    super.initState();
  }

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
          actions: <Widget>[
            Container(
              padding: EdgeInsets.only(right:50),
              child: Row(
                children:<Widget>[
                  FlatButton(
                    child: GestureDetector(
                      child:Text("FEES"),
                      onTap: () async{
                        setState(()=>onPay=true);
                        setState(()=>isLoading=true);
                        await _loadFees();
                        setState(()=>isLoading=false);
                      },
                    ),
                    onPressed: () async{
                      setState(()=>onPay=true);
                      setState(()=>isLoading=true);
                      await _loadFees();
                      setState(()=>isLoading=false);
                    }, 
                    textColor: Colors.white,
                  ),
                  FlatButton(
                    child: GestureDetector(
                      child:Text("TRANSACTIONS"),
                      onTap: () async{
                        setState(()=>onPay=false);
                        setState(()=>isLoading=true);
                        await _loadTransactions();
                        setState(()=>isLoading=false);
                      },
                    ),
                    onPressed: () async{
                      setState(()=>onPay=false);
                      setState(()=>isLoading=true);
                      await _loadTransactions();
                      setState(()=>isLoading=false);
                    }, 
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
            FlatButton(
              onPressed: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>main.LoginPage()), (route) => false);
              },
              textColor: Colors.white,
              child: Text("LOG OUT"),
            ),
          ],
        ),
        body: onPay?Payment():Transaction(),
      ),
    );
  }
}

class Closed extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("The Process is closed now!\nTry again later",style: TextStyle(fontWeight:FontWeight.bold,color:Colors.red),),
      ),
    );
  }
}

class Payment extends StatefulWidget {

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {

  String _fee(n,f){
    int paper=int.tryParse(n)??0;
    int paperFee=int.tryParse(f)??0;
    return (paper*paperFee).toString()+'.00';
  }
  String _total(){
    double theory = double.tryParse(_fee(fees['theory'],fees['theory_fee']))??0.00;
    double lab = double.tryParse(_fee(fees['lab'],fees['lab_fee']))??0.00;
    double fine = double.tryParse(fees['fine'])??0.00;
    setState(()=>total = (theory+lab+fine).toString()+'.00');
    return total; 
  }
  checkStatus()async{
    var check = await http.get("http://localhost/testing/sems/checkstatus.php?roll=$roll");
    if(check.body!='2' || check.body!='-1'){
      setState(() {
        isLoading=false;
      });
    }
    return check.body;
  }
  checkWindow(childWindow){
    print('Checking Window');
    if(childWindow.closed){
      print('Window closed');
      setState(() {
          isLoading=false;
        });
      return true;
    }
  }
  postCall(url,headers,jsonBody) async{
    var res = await dio.Dio().post(url,data:jsonBody,options: dio.Options(contentType:dio.Headers.formUrlEncodedContentType));
    if(res.data.toString()=="Success"){
      print("Payment Gateway connected");
      var res = await dio.Dio().post("http://localhost/testing/sems/paynow.php",data:{'roll':roll,'tnxid':utf8.decode(base64.decode(jsonBody['tnxid'])),'amount':utf8.decode(base64.decode(jsonBody['amount']))},options: dio.Options(contentType:dio.Headers.formUrlEncodedContentType));
      print(res.data);
      var childWindow = html.window.open(url+"?mer=${jsonBody['mid']}&tnx=${jsonBody['tnxid']}","Payment Gateway","width=300,height=200,alwaysRaised");
      
      Timer.periodic(Duration(seconds: 3), (Timer t){
        if(childWindow.closed){
          setState(() {
            onPay=true;
            isLoading=false;
          });
          Timer.run(() {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>ReLoadFee(roll)), (route) => false);
          });
          t.cancel();
        }
      });
      // Timer.periodic(Duration(seconds: 5), checkStatus());
    }else{
      print(res.data.toString());  
      setState(() {
        isLoading=false;
      });
    }
  }
  callPaymentGateway()async{
    var content = Utf8Encoder().convert(DateTime.now().millisecondsSinceEpoch.toString());
    var tnxid = md5.convert(content);

    var bytesMid = utf8.encode(main.merchantId);
    var bytesTnxid = utf8.encode(tnxid.toString());
    var bytesRoll = utf8.encode(roll);
    var bytesAmount = utf8.encode(total);

    var hashMid = sha1.convert(bytesMid);
    var hashTnxid = sha1.convert(bytesTnxid);
    var hashRoll = sha1.convert(bytesRoll);
    var hashAmount = sha1.convert(bytesAmount);

    var encryptedMid = base64.encode(main.merchantId.codeUnits);
    var encryptedTnxid = base64.encode(tnxid.toString().codeUnits);
    var encryptedRoll = base64.encode(roll.codeUnits);
    var encryptedAmount = base64.encode(total.codeUnits);

    Map<String,String> response = {
      "mid":encryptedMid.toString(),
      "tnxid":encryptedTnxid.toString(),
      "roll":encryptedRoll.toString(),
      "amount":encryptedAmount.toString(),
      "hash":json.encode(
        {
          "mid":hashMid.toString(),
          "tnxid":hashTnxid.toString(),
          "roll":hashRoll.toString(),
          "amount":hashAmount.toString(),
        } 
      )
    };
    // print(utf8.decode(base64.decode(encryptedRoll)));
    String url="http://127.0.0.1:8000/";
    Map<String,String> headers = {"Accept": "application/json","Content-Type": "application/x-www-form-urlencoded"};
    
    // print(response);
    await postCall(url,headers,response);
  }
  @override
  Widget build(BuildContext context) {
    return isLoading?Center(
      child:CircularProgressIndicator(),
    ):Center(
      child:Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        child:Card(
          elevation: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:<Widget>[
              ListTile(
                title:Row(
                  children: <Widget>[
                    RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '$roll', style: TextStyle(fontSize: MediaQuery.of(context).size.width<=500?15.0:22.0,color: Colors.grey))
                        ]
                      )
                    ),
                    Expanded(
                      child: Center(
                        child:RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'FEES', style: TextStyle(fontSize: 28.0,color: Colors.blueAccent))
                            ]
                          )
                        ),
                      ),
                    ),
                    RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '$roll', style: TextStyle(fontSize: MediaQuery.of(context).size.width<=500?15.0:22,color: Colors.white))
                        ]
                      )
                    ),
                  ],
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
                padding: EdgeInsets.symmetric(
                  vertical: 50,
                ),
                child:isLoading?Center(
                    child: CircularProgressIndicator(),
                  ):Center(
                    child: Container(
                      width: 400,
                      height: 320,
                      child: Card(
                        elevation:3,
                        child: fees['fine']=='-1'?Closed():Column(
                          children:<Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:5,
                                vertical:20,
                              ),
                              child:Table(
                                border:null,
                                children:[
                                  TableRow(
                                    children:[
                                      TableCell(child: Text("")),
                                      TableCell(child:Text("No of Papers",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text("Fee per paper",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text("Total",style: TextStyle(fontWeight:FontWeight.bold),)),
                                    ] 
                                  ),
                                  TableRow(
                                    children: [
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                    ]
                                  ),
                                  TableRow(
                                    children:[
                                      TableCell(child: Text("Theory",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text(fees['theory'])),
                                      TableCell(child:Text(fees['theory_fee'])),
                                      TableCell(child:Text("Rs."+_fee(fees['theory'],fees['theory_fee']),style: TextStyle(backgroundColor: Colors.blueAccent,color: Colors.white),)),
                                    ] 
                                  ),
                                  TableRow(
                                    children: [
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                    ]
                                  ),
                                  TableRow(
                                    children:[
                                      TableCell(child: Text("Lab",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text(fees['lab'])),
                                      TableCell(child:Text(fees['lab_fee'])),
                                      TableCell(child:Text("Rs."+_fee(fees['lab'],fees['lab_fee']),style: TextStyle(backgroundColor: Colors.blueAccent,color: Colors.white),)),
                                    ] 
                                  ),
                                  TableRow(
                                    children: [
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                    ]
                                  ),
                                  TableRow(
                                    children:[
                                      TableCell(child: Text("",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text("")),
                                      !isPaid?TableCell(child:Text("Fine",style: TextStyle(fontWeight:FontWeight.bold),)):TableCell(child: Text("")),
                                      !isPaid?TableCell(child:Text("Rs."+fees['fine'],style: TextStyle(backgroundColor: Colors.redAccent,color: Colors.white),)):TableCell(child: Text("")),
                                    ] 
                                  ),
                                  TableRow(
                                    children: [
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                      TableCell(child: Text("")),
                                    ]
                                  ),
                                  TableRow(
                                    children:[
                                      TableCell(child: Text("",style: TextStyle(fontWeight:FontWeight.bold),)),
                                      TableCell(child:Text("")),
                                      !isPaid?TableCell(child:Text("Total",style: TextStyle(fontWeight:FontWeight.bold),)):TableCell(child: Text("")),
                                      !isPaid?TableCell(child:Text("Rs."+_total(),style: TextStyle(backgroundColor: Colors.black,color: Colors.white),)):TableCell(child: Text("")),
                                    ] 
                                  ),
                                ]
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                children: <Widget>[
                                  RaisedButton(
                                    color: Colors.blueAccent,
                                    onPressed: isPaid?null:()async{
                                      if(!isLoading){
                                        setState(() {
                                          isLoading=true;
                                        });
                                        await callPaymentGateway();
                                      }
                                    },
                                    child: GestureDetector(
                                      child:Text(isPaid?fees['status']:"Pay Now",style: TextStyle(color:Colors.white),),
                                      onTap:isPaid?null:()async{
                                        if(!isLoading){
                                          setState(() {
                                            isLoading=true;
                                          });
                                          await callPaymentGateway();
                                        }
                                      },
                                    ),
                                  ),
                                  fees['status_id']=='1'?RaisedButton(
                                    onPressed: (){},
                                    color: Colors.blue,
                                    child:GestureDetector(
                                      onTap: (){},
                                      child: Text("Download Recipt",style: TextStyle(color:Colors.white),),
                                  )):Container(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
              ),
            ]
          ),
        ),
      )
    );
  }
}

class Transaction extends StatefulWidget {

  @override
  _TransactionState createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {

  Color _statusColor(i){
    if(transactions['tnx'][i]['status']=='Failed'){
      return Colors.red;
    }else if(transactions['tnx'][i]['status']=='Success'){
      return Colors.green;
    }
    return Colors.amberAccent;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading?Center(
      child:CircularProgressIndicator(),
    ):Center(
      child:Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        child:Card(
          elevation: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:<Widget>[
              ListTile(
                title:Row(
                  children: <Widget>[
                    RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '$roll', style: TextStyle(fontSize: MediaQuery.of(context).size.width<=500?15.0:22.0,color: Colors.grey))
                        ]
                      )
                    ),
                    Expanded(
                      child: Center(
                        child:RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'TRANSACTIONS', style: TextStyle(fontSize: MediaQuery.of(context).size.width<=500?18.0:28.0,color: Colors.redAccent)),
                            ]
                          )
                        ),
                      ),
                    ),
                    RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '$roll', style: TextStyle(fontSize: MediaQuery.of(context).size.width<=500?15.0:22.0,color: Colors.white))
                        ]
                      )
                    ),
                  ],
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
                child:isLoading?Center(
                  child: CircularProgressIndicator(),
                ):Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height-285,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child:ListView.builder(
                        scrollDirection: Axis.vertical,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context,index){
                          var transactionScroll = SingleChildScrollView(
                          child:Column(
                            children: <Widget>[
                              Container(
                                width: 500,
                                height: 70,
                                decoration: BoxDecoration(
                                  border:Border.all(width:3),
                                ),
                                  child:ListTile(
                                    title: Center(
                                      child:Column(
                                        children: <Widget>[
                                          RichText(text: TextSpan(
                                            children:[
                                              TextSpan(text:"Transaction id",style:TextStyle(fontWeight:FontWeight.bold,color: Colors.black)),
                                              TextSpan(text:" - "),
                                              TextSpan(text:transactions['tnx'][index]['tnxid'],style: TextStyle(color:Colors.black)),
                                            ]
                                          )),
                                          RichText(text: TextSpan(
                                            children:[
                                              TextSpan(text:transactions['tnx'][index]['time'],style:TextStyle(color: Colors.grey)),
                                              TextSpan(text:" | "),
                                              TextSpan(text:"Rs. ",style: TextStyle(color:Colors.black)),
                                              TextSpan(text:transactions['tnx'][index]['amount'],style: TextStyle(color:Colors.black)),
                                              TextSpan(text:" | "),
                                              TextSpan(text:transactions['tnx'][index]['status'],style: TextStyle(color:_statusColor(index))),
                                            ]
                                          )),
                                          RichText(text: TextSpan(
                                            children:[
                                              
                                            ]
                                          )),
                                        ],
                                      ),
                                    )
                                  )
                                ),
                                Container(
                                  height: 20,
                                )
                            ],
                          ),
                        scrollDirection: Axis.vertical,
                        );
                        return transactionScroll;
                      },
                      itemCount: transactions['count'],
                      shrinkWrap: true,
                      
                      )
                    ),
                  ),
                ),
              ),
            ]
          ),
        ),
      )
    );
  }
}