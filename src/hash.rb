class CustomHash
	def self.hash(str)
		hash = 0
		for i in 0..str.length - 1
			hash = hash * 31 + str[i].ord
			#Had to convert the character to an integer
		end 
		return hash.abs
	end 
end
