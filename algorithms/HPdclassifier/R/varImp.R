##This is a generic function for calculating permutation based variable importance
##This function requires a model with which to test as well as xtest,ytest variables 
##Also required is the a distance_metric function that can compare the loss in accuracy
##between predictions. 

varImportance <- function(model, xtest, ytest, distance_metric)
{
	if(!is.dframe(xtest) & !is.data.frame(xtest))
		stop("'xtest' must be a dframe or data.frame")
	if(!is.dframe(ytest) & !is.data.frame(ytest))
		stop("'ytest' must be a dframe or data.frame")
	if((is.dframe(xtest) & !is.dframe(ytest)) | 
		(!is.dframe(xtest) & is.dframe(ytest)))
		stop("'xtest' and 'ytest' must both be either a dframe or data.frame")
	if(ncol(ytest) != 1)
		stop("'ytest' must have exactly one column")
	if(nrow(ytest) != nrow(xtest))
		stop("'xtest' and 'ytest' must have same number of rows")

	#setting the shuffle function
	shuffle_column <- .shuffle_column_data_frame
	if(is.dframe(xtest))
	{
		shuffle_column <- .shuffle_column_dframe
		#if the input was a dframe first randomize data then set shuffle function
		permutation <- sample.int(nrow(xtest))
		suppressWarnings({
		xtest <- .shuffle_dframe(xtest,permutation)
		ytest <- .shuffle_dframe(ytest,permutation)
		})
	}

	#determine if the output is categorical or not
	#this is required to determine the default value of distance_metric
	categorical = FALSE
	if(is.dframe(ytest))
	{
		temp_categorical = dlist(npartitions = 1)
		foreach(i, 1, function(ytest = splits(ytest,i),
		       categorical = splits(temp_categorical,i))
		       {
				categorical = is.factor(ytest[,1]) | 
			    		    is.logical(ytest[,1]) |
			    		    is.character(ytest[,1])
				categorical = list(categorical)
				update(categorical)
		       },progress = FALSE)
		categorical = getpartition(temp_categorical)[[1]]
	}
	if(is.data.frame(ytest))
	{
		categorical = is.factor(ytest[,1]) | 
			    is.logical(ytest[,1]) |
			    is.character(ytest[,1])
	}
	if(missing(distance_metric))
	{
		if(categorical)
			distance_metric <- errorRate
		if(!categorical)
			distance_metric <- meanSquared
	}

	#this loop will shuffle the column locally and predict and 
	#compute the difference in errors
	importance = sapply(1:ncol(xtest), function(var)
	{
		shuffled_data <- shuffle_column(xtest, var)
		shuffled_predictions <- predict(model, shuffled_data)
		var_imp = distance_metric(ytest, shuffled_predictions)[1]
		return(var_imp)
	})

	names(importance) <- colnames(xtest)

	#compute the errors without any shuffling
	normal_predictions = predict(model, xtest)
	base_accuracy = distance_metric(ytest, normal_predictions)

	importance <- importance - base_accuracy
	importance <- as.data.frame(importance)
	colnames(importance) <- "Mean Decrease in Accuracy"
	return(importance)
}
	
##This function shuffles an individual column of a data.frame

.shuffle_column_data_frame <- function(data, column)
{
	shuffled_data <- data
	shuffled_data[,column]<-data[sample.int(nrow(data)),column]
	return(shuffled_data)
}

##This function shuffles an individual column of a dframe
##The shuffling only occurs locally. This is why there is a randomization
##if xtest is a dframe

.shuffle_column_dframe <- function(data, column)
{
	shuffled_data <- dframe(npartitions = npartitions(data))
	foreach(i,1:npartitions(data), 
		function(data = splits(data,i), 
		shuffled_data = splits(shuffled_data,i), 
		column = column)
		{
			shuffled_data = data
			shuffled_data[,column] = 
				data[sample.int(nrow(data)),column]
			update(shuffled_data)
		},progress = FALSE)
	colnames(shuffled_data) <- colnames(data)
	return(shuffled_data)
}

##This function shuffles/randomizes the dframe and mantains the
##size of each partition if desired for load balancing
##The idea of this is to reduce correlation between samples within the same split
##so that within each split we can shuffle locally  

.shuffle_dframe <- function(data,permutation)
{
	
	rows_partition = partitionsize(data)[,1]
	rows_partition = cumsum(rows_partition)
	start_rows_partition = c(1,rows_partition[-length(rows_partition)]+1)
	end_rows_partition = rows_partition
	shuffle_column = permutation
	dest_partition = sapply(shuffle_column, function(new) 
			      min(which((start_rows_partition <= new) &
			      	(new <= end_rows_partition))))



	#use a single foreach to set many partitions that will be redistributed
	
	temp_data = dframe(npartitions = npartitions(data)*npartitions(data))
	foreach(i,1:(npartitions(data)*npartitions(data)),
	function(source = ceiling(i/npartitions(data)),
		dest = (i %% npartitions(data))+1,
		temp_data = splits(temp_data,i), 
		data = splits(data,ceiling(i/npartitions(data))),
		dest_partition = dest_partition[
			start_rows_partition[ceiling(i/npartitions(data))]:
			end_rows_partition[ceiling(i/npartitions(data))]])
	{
		relevent_rows = dest_partition == dest
		temp_data = data.frame(data[relevent_rows,])
		update(temp_data)
	},progress = FALSE)



	#sending partitions to different workers and recombining 
	
	shuffled_data = dframe(npartitions = npartitions(data))
	foreach(i,1:npartitions(data),
	function(temp_data = splits(temp_data,
			as.list(npartitions(data)*(i-1)+1:npartitions(data))),
		shuffled_data = splits(shuffled_data,i),
		data = splits(data,i))
	{
		shuffled_data = do.call(rbind,temp_data)
		update(shuffled_data)
	},progress = FALSE)


	colnames(shuffled_data) <- colnames(data)
	return(shuffled_data)
}
