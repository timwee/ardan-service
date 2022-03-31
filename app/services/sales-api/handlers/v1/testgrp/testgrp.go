package testgrp

import (
	"context"
	"errors"
	"net/http"

	"math/rand"

	"github.com/timwee/service/business/sys/validate"
	"github.com/timwee/service/foundation/web"
	"go.uber.org/zap"
)

type Handlers struct {
	Log *zap.SugaredLogger
}

func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	if n := rand.Intn(100); n%2 == 0 {
		// return errors.New("untrusted error")
		return validate.NewRequestError(errors.New("trusted error"), http.StatusBadRequest)
		// return web.NewShutdownError("restart service")
	}
	status := struct {
		Status string
	}{
		Status: "Ok",
	}

	httpStatus := http.StatusOK
	return web.Respond(ctx, w, status, httpStatus)
}
