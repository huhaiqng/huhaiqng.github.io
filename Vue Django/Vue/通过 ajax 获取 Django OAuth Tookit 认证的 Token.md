### 通过 ajax 获取 Django OAuth Tookit 认证的 Token

```html
<!DOCTYPE html>
	<html lang="en">
	<head>
	    <meta charset="UTF-8">
	    <title>client</title>
	    <script src="http://libs.baidu.com/jquery/2.0.0/jquery.min.js"></script>
	</head>
	<body>
	    <h1>This is http_webapp, a client</h1>
	    <p>you can login or regist</p>
	    <a href="#"><strong>login</strong></a>
	    <a href="#"><strong>regist</strong></a>
	    <p>if you don't do that ,you can also tell us your username and password to access fk server</p>
	    username:<input type="text" name="username"><br>
	    password:<input type="password" name="password"><br>
	    <button class="send_data">获取令牌</button><br>
	    url: <input type="text" name="url"><br>
	    <button class="access_url">授权访问</button>
 
	    <script>
	        var tokenMsg;
	        $(".send_data").click(function () {
	            var data1={
	                grant_type:'password',
	                username:$("input[name='username']").val(),
	                password:$("input[name='password']").val(),
	                client_id:'2W1jMmm62jN80zCVydqefHuU2C2HVgsJmYoK1r7y',
	                client_secret:'sgbcMcmooZhoZnoJvQHYzUNLCLnhAuORoM4wD1jIuHy9GDxCj5uUupN6OTbGfnSWAQO9mhja9QbgHUjUqcNDqy8RpxKoTshhl5F6Ud7l85YpzaO6usvdz8wtiE2NJkwc',
	                scope:'write'
	            };
	            $.ajax({
	                url:'http://127.0.0.1:8000/o/token/',
	                type: 'POST',
	                data:data1,
	                success:function (data) {
	                    tokenMsg = data;
	                    alert("你的令牌是:"+data.access_token);
	                    console.log(data);
	                }
	            })
	        });
	        $(".access_url").click(function() {
	            var data2={
	                Authorization:tokenMsg.token_type ,
	                access_token:tokenMsg.access_token
	            };
	            $.ajax({
	                url:'http://127.0.0.1:8000/'+ $("input[name='url']").val(),
	                type: "GET",
	                data: data2,
	                success:function(msg){
	                    console.log(msg);
	                }
	            })
	        });
	    </script>
	</body>
	</html>
```

