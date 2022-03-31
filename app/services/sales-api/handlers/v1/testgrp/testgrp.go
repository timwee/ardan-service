package testgrp

import (
	"context"
	"net/http"

	"math/rand"

	"github.com/timwee/service/foundation/web"
	"go.uber.org/zap"
)

type Handlers struct {
	Log *zap.SugaredLogger
}

func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	if n := rand.Intn(100); n%2 == 0 {
		// return errors.New("untrusted error")
		// return validate.NewRequestError(errors.New("trusted error"), http.StatusBadRequest)
		// return web.NewShutdownError("restart service")
		panic("testing panic")
	}
	status := struct {
		Status string
	}{
		Status: "Ok",
	}

	httpStatus := http.StatusOK
	return web.Respond(ctx, w, status, httpStatus)
}
