/inet / && !/127.0.0.1/ {
	a = $2
	b = gensub("(.+)/.+","\\1",1,a)
	print b
}