### 通过 axios 获取 Django OAuth Toolkit 认证的 Token

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <button @click="getToken()">获取 Token</button>
        <p>{{ result }}</p>
        <button @click="getUsers()">读取 snippets 数据</button>
        <p> {{ users }}</p>
    </div>
    <script src="vue.js"></script>
    <script src="axios.min.js"></script>
    <script>
        var app = new Vue({
            el: '#app',
            data: {
                result: '',
                users: '',
            },
            methods: {
                getToken: function () {
                    var vm = this

                    let formData = new FormData() 
                    formData.append('username','admin')
                    formData.append('password','django')
                    formData.append('grant_type','password')
                    formData.append('scppe','write')
                    formData.append('client_id','2W1jMmm62jN80zCVydqefHuU2C2HVgsJmYoK1r7y')
                    formData.append('client_secret','sgbcMcmooZhoZnoJvQHYzUNLCLnhAuORoM4wD1jIuHy9GDxCj5uUupN6OTbGfnSWAQO9mhja9QbgHUjUqcNDqy8RpxKoTshhl5F6Ud7l85YpzaO6usvdz8wtiE2NJkwc')

                    axios({
                        method: 'post',
                        url: '/o/token/',
                        data: formData,
                        headers: {
                            "Content-Type": "application/x-www-form-urlencoded", 
                        },
                    }).then(function (response) {
                        vm.result=response.data
                    })
                },
            
                getUsers: function() {
                    vm = this
                    axios({
                        method: 'get',
                        url: '/snippets/',
                        params: {
                            'Authorization': vm.result.token_type,
	                        'access_token': vm.result.access_token
                        }
                    }).then(function (response) {
                        vm.users=response.data
                    })
                }
            }
        })
    </script>
</body>
</html>
```

