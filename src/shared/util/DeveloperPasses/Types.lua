
export type DeveloperPass = {
	Name: string?,
	ProductId: number,
	Callback: any--((Player)->boolean)
}

export type Error = {
	Message: string,
	Fatal: boolean
}

return nil