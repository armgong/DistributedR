library(HPdclassifier)
library(rpart)

nInst <- sum(distributedR_status()$Inst)
generateData <- function(nrow, ncol, 
	     features_categorical, response_categorical, 
	     npartitions = nInst)
{

	features_cardinality = 3
	response_cardinality = features_cardinality

	observations = lapply(1:ncol, 
	     function(i) sample.int(features_cardinality,nrow,replace=TRUE))
	observations = do.call(cbind,observations)
	observations = matrix(as.integer(observations),ncol=ncol)
	observations = data.frame(observations)

	responses = apply(observations,1,max)
	responses = as.numeric(responses)
	responses = data.frame(responses)

	indices = as.darray(matrix(1:nrow,ncol = 1))

	data = dframe(npartitions = npartitions)
	foreach(i,1:npartitions,function(
	data = splits(data,i),
	observations = observations[getpartition(indices,i),],
	responses = responses[getpartition(indices,i),],
	ncol = ncol(observations),
	response_categorical = response_categorical,
	features_categorical = features_categorical)
	{
		observations_dataframe = observations
		responses_dataframe = data.frame(matrix(responses,ncol=1))

		if(response_categorical)
		responses_dataframe[,1] = as.factor(responses_dataframe[,1])

		if(features_categorical)
		for(i in 1:ncol(observations_dataframe))
		      observations_dataframe[,i] = 
		      as.factor(observations_dataframe[,i])

		data = cbind(responses_dataframe, observations_dataframe)
		update(data)
	},progress = FALSE)
	rm(observations)
	rm(responses)
	colnames(data) <- paste("X",1:ncol(data),sep="")

	return(data)
}

data = generateData(100,2,TRUE,TRUE)
context("Invalid inputs to hpdrpart")

test_that("testing formula parameter", {
expect_error(hpdrpart(data = data),
				   "'formula' is a required argument")
expect_error(hpdrpart(1,data = data),
				   "'formula' is not of class formula")
expect_error(hpdrpart(X4 ~ .,data = data,do.trace = TRUE),
				   "unable to apply formula to 'data'")
expect_error(hpdrpart(X1 ~ X2 + X3 + X4,data = data),
				   "unable to apply formula to 'data'")

})

test_that("testing data parameter", {
expect_error(hpdrpart(X1 ~ .),
				   "'data' is a required argument")
expect_error(hpdrpart(X1 ~ .,data = matrix(1:9,3,3)),
				   "'data' must be a dframe or data.frame")
expect_error(hpdrpart(X1 ~ .,data = dframe(npartitions = c(1,2))),
				   "'data' must be partitioned rowise")

})

test_that("testing nBins parameter", {
expect_error(hpdrpart(X1 ~ .,data = data, nBins = -1),
				   "'nBins' must be more than 0")
expect_error(hpdrpart(X1 ~ .,data = data, nBins = 0),
				   "'nBins' must be more than 0")

})

test_that("testing na.action parameter", {
expect_error(hpdrpart(X1 ~ .,data = data, na.action = 0),
				   "'na.action' must be either na.exclude, na.omit, na.fail")

})


test_that("testing na.action parameter", {
expect_warning(hpdrpart(X1 ~ .,data = data, subset = 0),
				   "'subset' not implemented. Adjust using weights parameter")

})


context("Invalid Inputs to Predict Function")
model <- hpdrpart(X1 ~ ., data = data)
test_that("invalid newdata input to predict function",{
expect_error(predict(model), "'newdata' is a required argument")
expect_error(predict(model,newdata = matrix(1:9,3,3)),
				   "'newdata' must be a dframe or data.frame")
expect_error(predict(model,newdata = dframe(npartitions = c(1,2))),
				   "'newdata' must be partitioned rowise")
})


context("Validating Outputs of Training Function")
test_that("testing output for categorical trees", {
data = generateData(100,2,TRUE,TRUE)
model <- hpdrpart(X1 ~ ., data = data)

expect_true("frame" %in% names(model))
expect_true("splits" %in% names(model))
expect_true("csplit" %in% names(model))
expect_true("call" %in% names(model))
expect_true("terms" %in% names(model))
expect_true("variable.importance" %in% names(model))
expect_true("na.action" %in% names(model))
expect_true("control" %in% names(model))

})

test_that("testing output for numerical trees", {
data = generateData(100,2,FALSE,FALSE)
model <- hpdrpart(X1 ~ ., data = data)

expect_true("frame" %in% names(model))
expect_true("splits" %in% names(model))
expect_true("call" %in% names(model))
expect_true("terms" %in% names(model))
expect_true("variable.importance" %in% names(model))
expect_true("na.action" %in% names(model))
expect_true("control" %in% names(model))

})



context("Accuracy Results for Training Simple Models") 
test_that("basic training with categorical/categorical", {
set.seed(1)
data = generateData(1000,2,TRUE,TRUE)
model <- hpdrpart(X1 ~ ., data = data)

predictions = predict(model, data)
predictions = getpartition(predictions)$predictions
responses = getpartition(data)$X1
expect_equal(predictions,responses)
})

test_that("basic training with numeric/categorical", {
set.seed(1)
data = generateData(1000,2,FALSE,TRUE)
model <- hpdrpart(X1 ~ ., data = data)

predictions = predict(model, data)
predictions = getpartition(predictions)$predictions
responses = getpartition(data)$X1
expect_equal(predictions,responses)
})

test_that("basic training with categorical/numeric", {
set.seed(1)
data = generateData(1000,2,TRUE,FALSE)
model <- hpdrpart(X1 ~ ., data = data)

predictions = predict(model, data)
predictions = getpartition(predictions)$predictions
responses = getpartition(data)$X1
expect_equal(predictions,responses)
})

test_that("basic training with numeric/numeric", {
set.seed(1)
data = generateData(1000,2,FALSE,FALSE)
model <- hpdrpart(X1 ~ ., data = data)

predictions = predict(model, data)
predictions = getpartition(predictions)$predictions
responses = getpartition(data)$X1
expect_equal(predictions,responses)
})