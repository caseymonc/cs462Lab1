module.exports = (User) ->
	createUser: (req, res)->
		body = req.body
		user = new User body
		user.save (err) ->
			return res.send {error: true, message: err.message}, 500 if err?
			res.json user

	getUsersByGroup: (req, res) ->
		group = req.params.group
		User.getAllUsersForGroup group, (err, users) ->
			return res.json {error: true, message: err.message}, 500 if err?
			res.json users

	getUser: (req, res) ->
		email = req.params.email
		User.getUser email, (err, obj) ->
			return res.json {error: true, message: err.message}, 500 if err?
			if obj not null
				res.json obj
			else
				return res.json {error: true, message: "Not Found"}, 401

	getUserPermissions: (req, res) ->
		email = req.params.email
		User.getUser email, (err, obj) ->
			return res.json {error: true, message: err.message}, 500 if err?
			if obj is null then res.json [] else res.json obj.permissions

	deleteUser: (req, res) ->
		email = req.params.email
		User.getUser email, (err, obj) ->
			return res.json {error: true, message: err.message}, 500 if err?
			if obj not null
				obj.remove()
			res.json {message: "deleted"}, 200