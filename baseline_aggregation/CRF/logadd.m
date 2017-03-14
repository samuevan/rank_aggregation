function [out] = logadd(X, axis)

	maxX = max(X, [], axis);
	X_smaller = bsxfun(@minus, X, maxX);
	out = bsxfun(@plus, maxX, log(sum(exp(X_smaller), axis)));
end






