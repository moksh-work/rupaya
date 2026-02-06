export interface ApiRequest {
  endpoint: string;
  payload: any;
}

export interface ApiResponse {
  status: number;
  data: any;
  error?: string;
}